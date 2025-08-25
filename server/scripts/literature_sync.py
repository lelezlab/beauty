#!/usr/bin/env python3
"""
Pulls latest literature from PubMed & Semantic Scholar and writes to
- Supabase table `kb_articles` (if env set), or
- local file `server/rag/data/kb_articles.json`
"""
import os, json, time, urllib.parse, urllib.request

KEYWORDS = ["rhinoplasty", "blepharoplasty", "genioplasty", "mentocervical angle",
            "facial anthropometry", "aesthetic surgery guidelines"]

def pubmed_search(term, retmax=50):
    q = urllib.parse.urlencode({"db":"pubmed","term":term,"retmode":"json","retmax":retmax})
    url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?{q}"
    with urllib.request.urlopen(url) as r: data = json.load(r)
    ids = ",".join(data["esearchresult"].get("idlist", []))
    if not ids: return []
    url = f"https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi?db=pubmed&retmode=json&id={ids}"
    with urllib.request.urlopen(url) as r: s = json.load(r)
    out = []
    for k,v in s["result"].items():
        if k == "uids": continue
        out.append({
            "source":"pubmed",
            "pmid":k,
            "title":v.get("title"),
            "journal":v.get("fulljournalname"),
            "pubdate":v.get("pubdate"),
            "doi":(v.get("elocationid") or "").replace("doi: ",""),
            "authors":[a["name"] for a in v.get("authors",[])],
            "ts": int(time.time())
        })
    return out

def semanticscholar_search(term, limit=50):
    q = urllib.parse.urlencode({"query":term,"limit":limit,"fields":"title,year,externalIds,url,abstract"})
    url = f"https://api.semanticscholar.org/graph/v1/paper/search?{q}"
    try:
        with urllib.request.urlopen(url) as r: data = json.load(r)
    except Exception:
        return []
    out=[]
    for p in data.get("data",[]):
        out.append({
            "source":"semanticscholar",
            "title":p.get("title"),
            "year":p.get("year"),
            "doi": (p.get("externalIds") or {}).get("DOI"),
            "pmid": (p.get("externalIds") or {}).get("PubMed"),
            "url": p.get("url"),
            "abstract": p.get("abstract"),
            "ts": int(time.time())
        })
    return out

def merge_dedupe(items):
    seen=set(); out=[]
    for it in items:
        key = it.get("doi") or it.get("pmid") or it.get("title")
        if key in seen: continue
        seen.add(key); out.append(it)
    return out

def main():
    items=[]
    for kw in KEYWORDS:
        items += pubmed_search(kw, retmax=30)
        items += semanticscholar_search(kw, limit=30)
    items = merge_dedupe(items)
    os.makedirs("server/rag/data", exist_ok=True)
    with open("server/rag/data/kb_articles.json","w") as f:
        json.dump(items, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(items)} items to server/rag/data/kb_articles.json")

if __name__ == "__main__":
    main()


