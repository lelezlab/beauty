from fastapi import FastAPI
from pydantic import BaseModel
import base64

app = FastAPI(title="midas_stub")


class Body(BaseModel):
    image: str


@app.post("/ai/midas/depth")
def depth(body: Body):
    # Return base64 of the string 'DEPTH' as placeholder
    return {"depth_png": base64.b64encode(b"DEPTH").decode("utf-8")}



