#!/usr/bin/env python3
import argparse
import coremltools as ct

# Example: python3 scripts/export_coreml/arcface_to_coreml.py --onnx arcface.onnx --out ArcFace.mlpackage

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--onnx', required=True)
    ap.add_argument('--out', default='ArcFace.mlpackage')
    args = ap.parse_args()

    mlmodel = ct.convert(
        args.onnx,
        source='onnx',
        convert_to='mlprogram',
        inputs=[ct.ImageType(name='input', shape=(1,112,112,3), color_layout=ct.colorlayout.RGB)],
    )
    mlmodel.short_description = 'ArcFace 112x112 RGB -> 512D embedding'
    mlmodel.save(args.out)
    print('Saved', args.out)

if __name__ == '__main__':
    main()



