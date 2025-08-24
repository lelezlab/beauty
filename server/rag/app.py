from fastapi import FastAPI, Query
from pydantic import BaseModel
import json, os
from typing import List
from sentence_transformers import SentenceTransformer, util

app = FastAPI(title="Aesthetic-RAG")
MODEL = SentenceTransformer(os.getenv("EMB_MODEL","all-MiniLM-L6-v2"))

with open("server/rag/data/kb_articles.json","r") as f:
    KB = json.load(f)
EMB = MODEL.encode([ (it.get("title") or "") + " " + (it.get("abstract") or "") for it in KB ], normalize_embeddings=True)

class Answer(BaseModel):
    answer: str
    citations: List[dict]

@app.get("/ask", response_model=Answer)
def ask(q: str = Query(..., min_length=5), k: int = 5):
    qv = MODEL.encode([q], normalize_embeddings=True)
    sims = util.cos_sim(qv, EMB)[0]
    top = sims.topk(k)
    cites=[]
    for idx in top.indices:
        it = KB[int(idx)]
        cites.append({"title": it.get("title"), "doi": it.get("doi"), "pmid": it.get("pmid"), "url": it.get("url")})
    answer = "为你的问题检索到以下高相关文献，请与医生结合临床场景解读。"
    return {"answer": answer, "citations": cites}


