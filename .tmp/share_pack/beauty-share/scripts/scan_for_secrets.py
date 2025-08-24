#!/usr/bin/env python3
import sys, os, re, math
from pathlib import Path

PATTERNS = [
    re.compile(r"API_KEY|SECRET|TOKEN|ACCESS_KEY|SERVICE_ROLE|PRIVATE_KEY", re.I),
    re.compile(r"-----BEGIN (RSA|EC) PRIVATE KEY-----")
]

BIN_EXTS = {'.png','.jpg','.jpeg','.pdf','.zip','.onnx','.mlmodelc','.a','.dylib','.o','.xcarchive'}

def is_text(path: Path) -> bool:
    if path.suffix.lower() in BIN_EXTS: return False
    try:
        with open(path, 'rb') as f:
            chunk = f.read(2048)
            if b'\0' in chunk: return False
    except Exception:
        return False
    return True

def entropy(s: str) -> float:
    if not s: return 0.0
    probs = [float(s.count(c))/len(s) for c in set(s)]
    return -sum([p*math.log(p,2) for p in probs])

def scan(dir_path: Path):
    findings = []
    for root, _, files in os.walk(dir_path):
        for name in files:
            p = Path(root) / name
            if p.stat().st_size > 1024*1024: continue
            if not is_text(p): continue
            try:
                with open(p, 'r', errors='ignore') as f:
                    for i, line in enumerate(f, 1):
                        if any(pat.search(line) for pat in PATTERNS):
                            findings.append(f"{p}:{i}:{line.strip()[:160]}")
                        # high-entropy token heuristic
                        for token in re.findall(r"[A-Za-z0-9_\-=]{24,}", line):
                            if entropy(token) > 4.0 and not token.isupper():
                                findings.append(f"{p}:{i}:{token[:80]}…")
            except Exception:
                pass
    if findings:
        print("Sensitive items found:")
        for it in findings: print(it)
    else:
        print("No sensitive information found.")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: scan_for_secrets.py <dir>")
        sys.exit(2)
    scan(Path(sys.argv[1]))


