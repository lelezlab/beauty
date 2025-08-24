#!/usr/bin/env python3
import argparse, json, os, re, sys, hashlib, time, shutil, subprocess, pathlib
from urllib.request import urlopen, Request
import importlib
import importlib.resources as ir

ROOT = pathlib.Path(__file__).resolve().parents[1]
SPEC = ROOT / 'Resources' / 'Models' / 'models.spec.json'
LOCK = ROOT / 'Resources' / 'Models' / 'models.lock.json'

def sha256(path: pathlib.Path) -> str:
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1<<20), b''):
            h.update(chunk)
    return h.hexdigest()

def http_get(url: str) -> bytes:
    req = Request(url, headers={'User-Agent': 'models-sync/1.0'})
    with urlopen(req) as r:
        return r.read()

def ensure_dir(p: pathlib.Path):
    p.parent.mkdir(parents=True, exist_ok=True)

def download_to(url: str, dest: pathlib.Path):
    ensure_dir(dest)
    data = http_get(url)
    with open(dest, 'wb') as f: f.write(data)
    return dest

def github_latest_asset(repo: str, regex: str) -> (str, str):
    api = f'https://api.github.com/repos/{repo}/releases/latest'
    data = json.loads(http_get(api).decode('utf-8'))
    rx = re.compile(regex)
    for a in data.get('assets', []):
        if rx.search(a.get('name', '')):
            return a['browser_download_url'], data.get('tag_name')
    raise RuntimeError('asset not found')

def maybe_upload_mirror(mirror_base: str | None, local_path: pathlib.Path, dest_name: str) -> str:
    if not mirror_base:
        return ''
    # Simple HTTP PUT/POST is backend-specific; we only support pre-hosted mirrors via CI upload.
    # Return the would-be URL for lock rewrite.
    return f"{mirror_base.rstrip('/')}/{dest_name}"


def resolve_mediapipe_task(name: str, version: str) -> bytes:
    try:
        mp_mod = importlib.import_module('mediapipe.modules.face_landmarker')
        path = ir.files('mediapipe.modules.face_landmarker').joinpath('face_landmarker.task')
        with ir.as_file(path) as p:
            return open(p, 'rb').read()
    except Exception:
        # Fallback: official mirror URL (example)
        url = 'https://storage.googleapis.com/mediapipe-assets/face_landmarker.task'
        return http_get(url)


def convert_bisenet(repo_dir: pathlib.Path, weights_path: pathlib.Path, out_onnx: pathlib.Path):
    script = ROOT / 'scripts' / 'convert' / 'bisenet_pth_to_onnx.py'
    cmd = [sys.executable, str(script), str(weights_path), str(out_onnx)]
    print('Running', ' '.join(cmd))
    subprocess.check_call(cmd, cwd=str(repo_dir))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--mirror-base', default=None)
    args = ap.parse_args()

    spec = json.load(open(SPEC))
    out = { 'generated_at': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'models': [] }

    for m in spec['models']:
        mid = m['id']; dest = ROOT / m['dest']
        url = None; version = 'unknown'
        try:
            src = m['source']
            st = src['type']
            if st == 'github_release':
                url, version = github_latest_asset(src['repo'], src['asset_name_regex'])
                print('Downloading', mid, 'from', url)
                download_to(url, dest)
            elif st == 'mediapipe_task':
                data = resolve_mediapipe_task(src.get('name','face_landmarker'), src.get('version','latest'))
                ensure_dir(dest)
                with open(dest, 'wb') as f: f.write(data)
                version = src.get('version','latest')
                url = maybe_upload_mirror(args.mirror_base, dest, dest.name) or ''
            elif st == 'convert_from_repo':
                repo = src['repo']
                tmp = ROOT / '.model_build' / mid
                if tmp.exists(): shutil.rmtree(tmp)
                subprocess.check_call(['git', 'clone', '--depth=1', f'https://github.com/{repo}.git', str(tmp)])
                weights_hint = src.get('weights_hint', '79999_iter.pth')
                weights = tmp / weights_hint
                if not weights.exists():
                    # Try mirror
                    mirror = os.environ.get('MODEL_MIRROR_BASE')
                    if mirror:
                        wurl = f"{mirror.rstrip('/')}/{weights_hint}"
                        print('Downloading weights from mirror', wurl)
                        ensure_dir(weights)
                        with open(weights, 'wb') as f: f.write(http_get(wurl))
                if not weights.exists():
                    raise RuntimeError('weights not found; provide mirror MODEL_MIRROR_BASE')
                ensure_dir(dest)
                convert_bisenet(tmp, weights, dest)
                # Optional: onnxsim can be applied here
                version = 'repo-head'
                url = maybe_upload_mirror(args.mirror_base, dest, dest.name) or ''
            else:
                raise RuntimeError('unknown source type')

            # postprocess stubs
            for p in m.get('postprocess', []):
                if isinstance(p, str) and p == 'onnxsim':
                    pass
                elif isinstance(p, dict) and 'convert_coreml' in p:
                    # Optional: call coremltools via our lightweight script if present
                    pass

            h = sha256(dest); size = dest.stat().st_size
            final_url = url or ''
            if args.mirror_base:
                final_url = f"{args.mirror_base.rstrip('/')}/{dest.name}"
            out['models'].append({ 'id': mid, 'version': version, 'url': final_url, 'dest': str(m['dest']), 'size': size, 'sha256': h, 'license': m.get('license','') })
        except Exception as e:
            print('ERROR', mid, e, file=sys.stderr)
            sys.exit(2)

    with open(LOCK, 'w') as f: json.dump(out, f, indent=2)
    print('Wrote', LOCK)

    # Generate THIRD_PARTY_MODELS.md
    md = ["# Third-party Models", "", f"Generated at: {out['generated_at']}", ""]
    for m in out['models']:
        md.append(f"- **{m['id']}** — license: {m.get('license','-')} — url: {m.get('url','') or 'local'} — version: {m.get('version','')} → {m['dest']}")
    tp = ROOT / 'Resources' / 'Models' / 'THIRD_PARTY_MODELS.md'
    with open(tp, 'w') as f: f.write('\n'.join(md))
    print('Wrote', tp)

if __name__ == '__main__':
    main()


