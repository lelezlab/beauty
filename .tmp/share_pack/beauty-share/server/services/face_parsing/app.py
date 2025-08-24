from fastapi import FastAPI
from pydantic import BaseModel
import base64

app = FastAPI(title="face_parsing_stub")


class Body(BaseModel):
    image: str


@app.post("/ai/face-parsing")
def parse(body: Body):
    # Return a tiny 2x2 mask PNG (black/white checker)
    png = base64.b64encode(b"PNG").decode("utf-8")
    return {"mask_png": png, "classes": ["skin", "hair"]}



