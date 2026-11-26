#!/usr/bin/env python3
"""Restore and verify SK SCALE/ART S33 standalone QA source.
Requires Godot 4.7.2 executable; never overwrites a game project.
"""
import argparse, hashlib, json, pathlib, subprocess, sys, tempfile, zipfile

EXPECTED_ARCHIVE = "556bdb4e1370306cdbcfc3777bf24ec7b060fca5d772bd3eb24461c5b4437b0b"
TESTS = ["s32_camera_ownership_test.gd", "s31_transition_repeat_test.gd", "s30_vertical_camera_test.gd", "s29_traversal_test.gd", "s28_input_camera_test.gd", "s27_motion_test.gd", "s23_input_art_test.gd"]

def verify(archive, godot, expected_sha=EXPECTED_ARCHIVE):
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    if digest != expected_sha:
        raise ValueError(f"S32 source ZIP SHA mismatch: {digest}")
    with tempfile.TemporaryDirectory(prefix="sk-s33-restore-") as folder:
        root=pathlib.Path(folder)
        with zipfile.ZipFile(archive) as z:
            bad=z.testzip()
            if bad: raise ValueError(f"ZIP CRC failure: {bad}")
            if any(pathlib.PurePosixPath(n).is_absolute() or '..' in pathlib.PurePosixPath(n).parts for n in z.namelist()):
                raise ValueError("Archive contains unsafe path")
            z.extractall(root)
        imp=subprocess.run([godot,'--headless','--path',str(root),'--editor','--quit'],capture_output=True,text=True,timeout=90)
        results=[]
        for test in TESTS:
            run=subprocess.run([godot,'--headless','--path',str(root),'--script','res://tests/'+test],capture_output=True,text=True,timeout=90)
            out=run.stdout+'\n'+run.stderr
            results.append({'test':test,'returncode':run.returncode,'passed':run.returncode==0,'result_lines':[line for line in out.splitlines() if 'RESULT' in line]})
        return {'archive_sha256':digest,'import_returncode':imp.returncode,'tests':results,'pass':imp.returncode==0 and all(x['passed'] for x in results)}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('archive',type=pathlib.Path);p.add_argument('--godot',default='godot');a=p.parse_args()
    try:
        result=verify(a.archive,a.godot)
        print(json.dumps(result,indent=2));sys.exit(0 if result['pass'] else 1)
    except Exception as error:
        print(json.dumps({'pass':False,'error':str(error)}));sys.exit(1)
