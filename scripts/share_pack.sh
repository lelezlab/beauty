#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
OUT_DIR="$HOME/Documents/share"
STAMP=$(date +%Y%m%d-%H%M)
WORK_DIR="$ROOT_DIR/.tmp/share_pack"
PKG_DIR="$WORK_DIR/beauty-share"
ZIP_PATH="$OUT_DIR/beauty-share-$STAMP.zip"
REPORT_PATH="$WORK_DIR/share-pack-report.md"

mkdir -p "$OUT_DIR"
rm -rf "$WORK_DIR" && mkdir -p "$PKG_DIR"

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || { echo "Missing command: $1. Please install it (macOS: brew install $1)."; exit 1; }
}

need_cmd rsync
need_cmd zip
need_cmd python3

echo "==> Copying sources with rsync (excluding build artifacts/secrets)"
RSYNC_EXCLUDES=(
  "--exclude=.git/"
  "--exclude=DerivedData/" "--exclude=build/" "--exclude=.build/" "--exclude=SourcePackages/"
  "--exclude=Pods/" "--exclude=Carthage/Build/"
  "--exclude=Documents/proof/" "--exclude=*.ipa" "--exclude=*.dSYM" "--exclude=*.xcarchive"
  "--exclude=**/.DS_Store" "--exclude=**/xcuserdata/"
  "--exclude=Resources/Models/*"
  "--include=Resources/Models/models.spec.json"
  "--include=Resources/Models/models.lock.json"
  "--include=Resources/Models/THIRD_PARTY_MODELS.md"
  "--exclude=*.pem" "--exclude=*.p12" "--exclude=*.mobileprovision"
  "--exclude=**/manifest_signing_private.pem" "--exclude=**/manifest_signing_public.pem"
  "--exclude=beauty/Config/Supabase.xcconfig"
)
rsync -a --delete "${RSYNC_EXCLUDES[@]}" "$ROOT_DIR/" "$PKG_DIR/"

# Supabase example xcconfig
if [ -f "$ROOT_DIR/beauty/Config/Supabase.xcconfig" ]; then
  mkdir -p "$PKG_DIR/beauty/Config"
  cat > "$PKG_DIR/beauty/Config/Supabase.example.xcconfig" <<EOF
SUPABASE_URL=<SUPABASE_URL>
SUPABASE_ANON_KEY=<ANON_KEY>
SUPABASE_SERVICE_ROLE=<SERVICE_ROLE>
EOF
fi

echo "==> Building project inventory"
INV="$PKG_DIR/project-inventory.txt"
{
  echo "# Project Inventory"
  echo "Generated: $(date)"
  echo
  echo "## Xcode Targets & Schemes"
  if command -v /usr/bin/xcodebuild >/dev/null 2>&1; then
    (cd "$ROOT_DIR" && /usr/bin/xcodebuild -list 2>/dev/null || true)
  else
    echo "xcodebuild not found"
  fi
  echo
  echo "## Swift files distribution"
  (cd "$ROOT_DIR" && find beauty -name '*.swift' | sed 's|/[^/]*$|/|g' | sort | uniq -c | sort -nr | head -n 200)
  echo
  echo "## Package.resolved summary"
  (cd "$ROOT_DIR" && find . -name Package.resolved -maxdepth 3 -print -exec sh -c 'echo ==== {}; cat {} | head -n 50' \; )
  echo
  echo "## Podfile snapshot"
  [ -f "$ROOT_DIR/Podfile" ] && (sed -n '1,120p' "$ROOT_DIR/Podfile") || echo "No Podfile"
  echo
  echo "## Main Info.plist keys"
  if /usr/libexec/PlistBuddy -c 'Print' "$ROOT_DIR/beauty/beauty/Info.plist" >/dev/null 2>&1; then
    /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$ROOT_DIR/beauty/beauty/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT_DIR/beauty/beauty/Info.plist" 2>/dev/null || true
    /usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$ROOT_DIR/beauty/beauty/Info.plist" 2>/dev/null || true
  else
    echo "Info.plist not found or PlistBuddy missing"
  fi
} > "$INV"

echo "==> Scanning for secrets"
SCAN_OUT="$WORK_DIR/scan.txt"
python3 "$ROOT_DIR/scripts/scan_for_secrets.py" "$PKG_DIR" > "$SCAN_OUT" || true

echo "==> Creating report"
FILE_COUNT=$( (cd "$PKG_DIR" && find . -type f | wc -l | tr -d ' ') )
TOTAL_SIZE_MB=$( (cd "$PKG_DIR" && du -sk . | awk '{printf "%.2f", $1/1024}') )
BRANCH=$(cd "$ROOT_DIR" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(cd "$ROOT_DIR" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")

{
  echo "# Share Pack Report"
  echo
  echo "- Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
  echo "- Branch: $BRANCH"
  echo "- Commit: $COMMIT"
  echo "- Files: $FILE_COUNT"
  echo "- Size: ${TOTAL_SIZE_MB} MB"
  echo
  echo "## Exclude rules"
  printf '%s\n' "${RSYNC_EXCLUDES[@]}" | sed 's/^/- /'
  echo
  echo "## Key paths snapshot (top-level)"
  (cd "$PKG_DIR" && find . -maxdepth 2 | sed 's|^./||' | sort | head -n 200)
  echo
  echo "## Secrets scan"
  cat "$SCAN_OUT"
  echo
  echo "## Required manifests"
  for f in Resources/Models/models.spec.json Resources/Models/models.lock.json Resources/Models/THIRD_PARTY_MODELS.md beauty/Config/Supabase.example.xcconfig; do
    if [ -f "$PKG_DIR/$f" ]; then echo "- [x] $f"; else echo "- [ ] $f"; fi
  done
  echo
  echo "## Build environment"
  echo "- Xcode: $(xcodebuild -version 2>/dev/null | tr '\n' ' ' || echo unknown)"
  echo "- iOS minimum: $(/usr/libexec/PlistBuddy -c 'Print :MinimumOSVersion' "$ROOT_DIR/beauty/beauty/Info.plist" 2>/dev/null || echo unknown)"
} > "$REPORT_PATH"

echo "==> Zipping"
(cd "$WORK_DIR" && zip -qr "$ZIP_PATH" "$(basename "$PKG_DIR")")

# Include local proof artifacts: edge_recon + ai_metrics + mirror + cases
copy_dir() {
  local name="$1"
  local path="$HOME/Documents/proof/$name"
  local dest="$PKG_DIR/Documents/proof/$name"
  if [ -d "$path" ]; then
    mkdir -p "$dest"
    rsync -a "$path/" "$dest/"
  else
    echo "$name directory not found at $path" >&2
  fi
}
copy_dir edge_recon
copy_dir ai_metrics
copy_dir mirror
copy_dir cases

echo "ZIP_PATH=$ZIP_PATH"
FINAL_REPORT="$OUT_DIR/share-pack-report.md"
cp "$REPORT_PATH" "$FINAL_REPORT"
echo "REPORT_PATH=$FINAL_REPORT"


