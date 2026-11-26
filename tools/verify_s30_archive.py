#!/usr/bin/env python3
"""Verify the canonical SK SCALE/ART S30 handoff ZIP, not the original full game."""
from __future__ import annotations
import argparse
import hashlib
import json
import zipfile
from pathlib import Path

EXPECTED_SHA256 = "8607d10dd6238e88364874a1eead4571f4b86c5acd1a75f9a02f320f4ff6d53c"
EXPECTED = (
    "project.godot",
    "scripts/sk_s25_stage.gd",
    "scripts/sk_crouch_adapter.gd",
    "scripts/sk_s23_visual_driver.gd",
    "scenes/sk_s25_visual_reintegration.tscn",
    "assets/knight_standing.png",
    "assets/knight_crouching.png",
    "tests/s30_vertical_camera_test.gd",
    "S30_VERIFICATION.json",
)

def verify(path: Path) -> dict:
    digest = hashlib.sha256(path.read_bytes()).hexdigest()
    with zipfile.ZipFile(path) as archive:
        bad_member = archive.testzip()
        names = archive.namelist()
        missing = [name for name in EXPECTED if not any(n == name or n.endswith("/" + name) for n in names)]
    result = {
        "archive": str(path), "sha256": digest,
        "canonical_s30_match": digest == EXPECTED_SHA256,
        "crc_ok": bad_member is None,
        "missing_expected_paths": missing,
        "member_count": len(names),
    }
    result["pass"] = result["canonical_s30_match"] and result["crc_ok"] and not missing
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("archive", type=Path)
    args = parser.parse_args()
    result = verify(args.archive)
    print(json.dumps(result, indent=2))
    raise SystemExit(0 if result["pass"] else 1)
