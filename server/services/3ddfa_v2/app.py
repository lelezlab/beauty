from fastapi import FastAPI
from pydantic import BaseModel
from typing import List, Dict, Any

app = FastAPI(title="3DDFA_V2 (stub)")


class ReconBody(BaseModel):
    images: List[str]
    retopo: str | None = None


@app.post("/ai/3ddfa/recon")
def recon(body: ReconBody) -> Dict[str, Any]:
    # Stub: return a tiny triangle mesh with placeholders and params
    vertices = [[0, 0, 0], [1, 0, 0], [0, 1, 0]]
    indices = [[0, 1, 2]]
    uv = [[0, 0], [1, 0], [0, 1]]
    landmarks68 = [[0.1, 0.1, 0] for _ in range(68)]
    params = {"identity": [0.0], "expression": [0.0], "pose": [0.0, 0.0, 0.0], "scale": 1.0}
    return {
        "vertices": vertices,
        "indices": indices,
        "uv": uv,
        "landmarks68": landmarks68,
        "params": params,
    }


@app.get("/")
def root():
    return {"status": "ok", "service": "3ddfa_v2_stub"}



