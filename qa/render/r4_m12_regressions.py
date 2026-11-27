#!/usr/bin/env python3
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import json, os, re, subprocess, sys
root=Path(__file__).resolve().parent.parent
prior=json.loads((root/'reports/R4_M11_INHERITED_REGRESSIONS.json').read_text())
gate=json.loads((root/'reports/R4_M11_PREVIOUS_GATEWAYS.json').read_text())
tests=[(row['suite'],row['expected']) for row in prior]+[(row['suite'],row['expected']) for row in gate]
tests.append(('r4_m11_provider_test.gd',84))
assert len(tests)==23 and len({p for p,_ in tests})==23
binary=Path('/mnt/data/bin/Godot_v4.7.2-stable_linux.x86_64')
env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1')
def check(t):
    path,expected=t
    try:
        result=subprocess.run([str(binary),'--headless','--fixed-fps','60','--path',str(root),
            '--script','res://tests/'+path,'--','41','4'],capture_output=True,text=True,env=env,timeout=100)
        output=result.stdout+'\n'+result.stderr
        tail=[line for line in output.splitlines() if line.strip()]
        match=re.search(r'\b(?:checks|assertions)=(\d+)\s+failures=(\d+)',output)
        if match:
            actual,failures=int(match.group(1)),int(match.group(2))
        else:
            candidates=[re.search(r'(?:PASS|pass(?:ed)?)\s+(\d+)\s+assertions?',line,re.I) for line in tail]
            matches=[int(x.group(1)) for x in candidates if x]
            actual=matches[-1] if matches else None
            failures=0 if actual is not None else None
        passed=result.returncode==0 and actual==expected and failures==0
        return {'suite':path,'expected':expected,'actual':actual,'failures':failures,'return_code':result.returncode,
            'passed':passed,'last':tail[-3:]}
    except Exception as exc:
        return {'suite':path,'expected':expected,'actual':None,'passed':False,'error':str(exc)}
rows=[]
with ThreadPoolExecutor(max_workers=4) as pool:
    for future in as_completed([pool.submit(check,t) for t in tests]):
        row=future.result();rows.append(row)
        print('R4_M12_REGRESSION %s %s/%s PASS=%s'%(row['suite'],row['actual'],row['expected'],row['passed']),flush=True)
rows.sort(key=lambda row:row['suite'])
(root/'reports/R4_M12_INHERITED_REGRESSIONS.json').write_text(json.dumps(rows,indent=2)+'\n')
print('R4_M12_REGRESSION_SUMMARY suites=%d assertions=%d failures=%d'%(len(rows),
    sum(int(r['actual'] or 0) for r in rows),sum(not r['passed'] for r in rows)))
sys.exit(0 if all(r['passed'] for r in rows) else 1)
