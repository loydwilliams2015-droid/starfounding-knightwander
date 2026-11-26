#!/usr/bin/env python3
"""SK-ENG-C02: exact-byte local source custody gate; never implies GitHub backup."""
import hashlib, json, sys, zipfile
from pathlib import Path
EXPECTED_S32 = "556bdb4e1370306cdbcfc3777bf24ec7b060fca5d772bd3eb24461c5b4437b0b"
EXPECTED_S33 = "5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283"
def sha(data): return hashlib.sha256(data).hexdigest()
def audit(s32, s33, manifest):
    m=json.loads(manifest.read_text())
    ok=sha(s32.read_bytes())==EXPECTED_S32 and sha(s33.read_bytes())==EXPECTED_S33
    with zipfile.ZipFile(s32) as a, zipfile.ZipFile(s33) as b:
        ok=ok and a.testzip() is None and b.testzip() is None
        missing=[]
        for f in m["files"]:
            try: content=a.read(f["path"])
            except KeyError: missing.append(f["path"]); continue
            if sha(content)!=f["sha256"] or len(content)!=f["bytes"]: missing.append(f["path"])
    return {"pass":ok and not missing and len(m["files"])==168,"files_checked":len(m["files"]),"mismatches":missing,"remote_custody_verified":False}
if __name__=="__main__":
    if len(sys.argv)!=4: sys.exit("Usage: c02_source_audit.py S32.zip S33.zip S33_FILE_MANIFEST.json")
    result=audit(*map(Path,sys.argv[1:]))
    print(json.dumps(result,indent=2))
    sys.exit(0 if result["pass"] else 1)
