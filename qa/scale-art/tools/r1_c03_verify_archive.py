#!/usr/bin/env python3
"""R1-C03: checksum + 168-file integrity gate for downloaded S33 archive."""
import argparse
import hashlib
import json
import pathlib
import sys
import zipfile

S33_SHA="5656c44acf792a88b5d78a14aa148a869a1b5434bc81d709a517f20c44fec283"
S32_SHA="556bdb4e1370306cdbcfc3777bf24ec7b060fca5d772bd3eb24461c5b4437b0b"

def hash_bytes(raw):
    return hashlib.sha256(raw).hexdigest()

def verify(path):
    raw=path.read_bytes()
    faults=[]
    if hash_bytes(raw)!=S33_SHA:
        faults.append("S33 archive SHA-256 mismatch")
    with zipfile.ZipFile(path) as bundle:
        invalid=bundle.testzip()
        if invalid: faults.append("CRC failed: "+invalid)
        files=set(bundle.namelist())
        if "S33_FILE_MANIFEST.json" not in files:
            faults.append("source manifest missing")
            manifest={"files":[],"source_count":0}
        else:
            manifest=json.loads(bundle.read("S33_FILE_MANIFEST.json"))
        if manifest.get("source_count")!=168 or len(manifest["files"])!=168:
            faults.append("original source inventory must contain 168 records")
        if manifest.get("source_archive_sha256")!=S32_SHA:
            faults.append("S32 source archive checksum mismatch")
        for item in manifest["files"]:
            name=item["path"]
            if name not in files:
                faults.append("missing: "+name)
                continue
            blob=bundle.read(name)
            if len(blob)!=item["bytes"] or hash_bytes(blob)!=item["sha256"]:
                faults.append("incorrect bytes: "+name)
        for name in files:
            parts=pathlib.PurePosixPath(name)
            if parts.is_absolute() or '..' in parts.parts:
                faults.append("unsafe path: "+name)
    return {"ok":not faults, "sha256":hash_bytes(raw),
            "source_files_checked":len(manifest["files"]),
            "problems":faults,
            "scope":"standalone SCALE/ART QA, not the original playable game"}

if __name__=="__main__":
    p=argparse.ArgumentParser()
    p.add_argument("archive",type=pathlib.Path)
    args=p.parse_args()
    try: result=verify(args.archive)
    except Exception as exc: result={"ok":False,"problems":[str(exc)]}
    print(json.dumps(result,indent=2))
    sys.exit(0 if result["ok"] else 1)
