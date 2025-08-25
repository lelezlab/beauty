#!/usr/bin/env python3
import argparse, json, os, glob
import numpy as np
from PIL import Image
import onnxruntime as ort

TEMPLATE = np.array([
  [38.2946, 51.6963],
  [73.5318, 51.5014],
  [56.0252, 71.7366],
  [41.5493, 92.3655],
  [70.7299, 92.2041]
], dtype=np.float32)

def umeyama(src, dst):
  src, dst = src.astype(np.float64), dst.astype(np.float64)
  mu_src, mu_dst = src.mean(0), dst.mean(0)
  src_c, dst_c = src - mu_src, dst - mu_dst
  cov = src_c.T @ dst_c / src.shape[0]
  U, S, Vt = np.linalg.svd(cov)
  R = U @ Vt
  if np.linalg.det(R) < 0:
    U[:, -1] *= -1; R = U @ Vt
  var_src = (src_c**2).sum()/src.shape[0]
  scale = S.sum() / var_src
  T = np.eye(3); T[:2,:2] = scale * R; T[:2,2] = mu_dst - scale * R @ mu_src
  return T

def align_chip(img, pts5):
  T = umeyama(np.array(pts5, np.float32), TEMPLATE)
  return Image.fromarray(
    cv2.warpAffine(np.array(img.convert('RGB')), T[:2], (112,112), flags=cv2.INTER_LINEAR, borderMode=cv2.BORDER_REFLECT_101)
  )

def preprocess(img: Image.Image):
  img = img.convert('RGB').resize((112,112))
  arr = (np.array(img).astype(np.float32) - 127.5)/128.0
  arr = np.transpose(arr, (2,0,1))[None, ...]
  return arr

def main():
  ap = argparse.ArgumentParser()
  ap.add_argument("--gallery_dir", required=True)
  ap.add_argument("--onnx", default="arcface.onnx")
  ap.add_argument("--out", default="celeb_index")
  ap.add_argument("--landmarks_csv", default=None)
  args = ap.parse_args()
  sess = ort.InferenceSession(args.onnx, providers=['CPUExecutionProvider'])

  # names.csv
  meta = {}
  with open(os.path.join(args.gallery_dir,'names.csv'), 'r', encoding='utf-8') as f:
    header = f.readline().strip().split(',')
    for line in f:
      vals = line.strip().split(',')
      row = dict(zip(header, vals))
      meta[row['id']] = row

  # optional landmarks
  lm = {}
  if args.landmarks_csv and os.path.exists(args.landmarks_csv):
    with open(args.landmarks_csv, 'r', encoding='utf-8') as f:
      f.readline()
      for line in f:
        vals = line.strip().split(',')
        fid = vals[0]
        pts = np.array(list(map(float, vals[1:])), dtype=np.float32).reshape(5,2)
        lm[fid] = pts

  embs, ids = [], []
  os.makedirs(args.out, exist_ok=True)
  os.makedirs(os.path.join(args.out, 'aligned_samples'), exist_ok=True)
  imgs = sorted(glob.glob(os.path.join(args.gallery_dir, 'images', '*.jpg')))
  for i, p in enumerate(imgs):
    fid = os.path.splitext(os.path.basename(p))[0]
    if fid not in meta: continue
    img = Image.open(p)
    if fid in lm:
      try:
        import cv2  # only used when landmarks provided
        chip = align_chip(img, lm[fid])
      except Exception:
        chip = img
    else:
      chip = img
    if i < 10:
      chip.save(os.path.join(args.out, 'aligned_samples', fid + '.jpg'))
    x = preprocess(chip)
    y = sess.run(None, {sess.get_inputs()[0].name: x})[0][0]
    y = y / np.linalg.norm(y)
    embs.append(y.astype('float32'))
    ids.append(fid)

  np.savez(os.path.join(args.out, 'embeddings.npz'), ids=np.array(ids), embs=np.stack(embs))
  with open(os.path.join(args.out, 'metadata.json'), 'w', encoding='utf-8') as f:
    json.dump({i:meta[i] for i in ids}, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
  main()


