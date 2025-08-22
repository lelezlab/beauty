#!/usr/bin/env python3
import argparse
import coremltools as ct

parser = argparse.ArgumentParser()
parser.add_argument("--onnx", required=True)
parser.add_argument("--out", default="ArcFace.mlpackage")
args = parser.parse_args()

mlmodel = ct.convert(
    args.onnx,
    source="onnx",
    convert_to="mlprogram",
    inputs=[ct.ImageType(name="input", shape=(1,112,112,3), color_layout=ct.colorlayout.RGB)],
)
mlmodel.short_description = "ArcFace/MobileFaceNet 112x112 RGB -> 512D embedding"
mlmodel.save(args.out)
print("Saved:", args.out)


