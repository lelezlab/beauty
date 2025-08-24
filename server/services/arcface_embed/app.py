from fastapi import FastAPI
from pydantic import BaseModel
from typing import List

app = FastAPI(title="arcface_embed_stub")


class Body(BaseModel):
    image: str


@app.post("/ai/arcface/embed")
def embed(body: Body):
    v = [0.0] * 512
    v[0] = 1.0
    return {"embedding": v, "norm": 1.0}



