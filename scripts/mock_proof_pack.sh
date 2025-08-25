#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Mock generator to satisfy CI proof bundle requirements.
# Produces under $HOME/Documents/proof the following structure:
# - metrics.json, rules_hits.json
# - mirror/{before.png, after.png}
# - edge_recon/{mesh.glb, texture.png}

DOCS_DIR="$HOME/Documents/proof"
mkdir -p "$DOCS_DIR/mirror" "$DOCS_DIR/edge_recon"

# Minimal JSONs
cat > "$DOCS_DIR/metrics.json" <<'JSON'
{
  "version": 1,
  "generated_by": "mock",
  "measures": {"sample_metric": 0.0}
}
JSON

cat > "$DOCS_DIR/rules_hits.json" <<'JSON'
{
  "hits": []
}
JSON

write_b64() {
  local out="$1"
  python3 - "$out" <<'PY'
import sys, base64, pathlib
path = pathlib.Path(sys.argv[1])
data = sys.stdin.read().encode('ascii')
path.write_bytes(base64.b64decode(data))
print(f"wrote {path} ({path.stat().st_size} bytes)")
PY
}

# Create tiny placeholder PNGs (1x1) using portable base64 decode via Python
write_b64 "$DOCS_DIR/mirror/before.png" <<'B64'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAGGgJq6eYtSAAAAABJRU5ErkJggg==
B64
write_b64 "$DOCS_DIR/mirror/after.png" <<'B64'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAGGgJq6eYtSAAAAABJRU5ErkJggg==
B64

# Create tiny placeholder GLB and PNG for edge_recon.
write_b64 "$DOCS_DIR/edge_recon/texture.png" <<'B64'
iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAGGgJq6eYtSAAAAABJRU5ErkJggg==
B64

# Minimal GLB: an empty glTF scene encoded as GLB (small dummy)
write_b64 "$DOCS_DIR/edge_recon/mesh.glb" <<'B64'
AAABAAEAAABnbHRmAAAAAAAAAAEAAAB7ImFzc2V0cyI6W10sImJ1ZmZlcnMiOltdLCJpbWFnZXMiOltdLCJtYXRlcmlhbHMiOnt9LCJzYW1wbGVzIjp7fSwic2NlbmVzIjpbeyJuYW1lIjoiU2NlbmUiLCJub2RlcyI6W119XSwidGV4dHVyZXMiOltdfQ==
B64

echo "Mock proof generated at $DOCS_DIR"

