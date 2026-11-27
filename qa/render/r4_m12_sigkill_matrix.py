#!/usr/bin/env python3
"""Kill only a disposable Godot child process in r4m11_test_r4m12_cross* namespaces."""
from pathlib import Path
import argparse, json, os, select, signal, subprocess, sys, time

def run(root, godot, seed, screens):
    base=[str(godot),'--headless','--fixed-fps','60','--path',str(root),'--script','res://tests/r4_m12_cross_process.gd','--']
    env=dict(os.environ,GODOT_SILENCE_ROOT_WARNING='1')
    logdir=root/'reports';logdir.mkdir(parents=True,exist_ok=True)
    writer=subprocess.Popen(base+['write',str(seed),str(screens)],stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
        text=True,bufsize=1,env=env,preexec_fn=os.setsid)
    lines=[];ready=False;deadline=time.monotonic()+90
    try:
        while time.monotonic()<deadline:
            assert writer.stdout is not None
            r,_,_=select.select([writer.stdout],[],[],0.25)
            if r:
                line=writer.stdout.readline()
                if line:
                    lines.append(line)
                    if 'R4_M12_CROSS_READY' in line:
                        ready=True;break
            if writer.poll() is not None:break
    finally:
        if writer.poll() is None:
            os.killpg(writer.pid,signal.SIGKILL)
            writer.wait(timeout=6)
    (logdir/f'R4_M12_SIGKILL_WRITER_{seed}_{screens}.log').write_text(''.join(lines))
    if not ready:
        return {'passed':False,'error':'writer never reached READY','seed':seed,'screens':screens,'log':''.join(lines[-8:])}
    results={}
    for mode in ['recover','replay']:
        command=base+[mode,str(seed),str(screens)]
        p=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
            text=True,timeout=80,env=env)
        (logdir/f'R4_M12_CROSS_{mode}_{seed}_{screens}.log').write_text(p.stdout)
        key=f'R4_M12_CROSS_RESULT mode={mode}'
        summary=next((x for x in p.stdout.splitlines() if key in x),'')
        results[mode]={'passed':p.returncode==0 and 'failures=0' in summary,'summary':summary,'exit':p.returncode}
        if not results[mode]['passed']:results[mode]['log_end']=p.stdout.splitlines()[-12:]
        if not results[mode]['passed']:break
    return {'passed':bool(results.get('recover',{}).get('passed') and results.get('replay',{}).get('passed')),
        'seed':seed,'screens':screens,'writer_killed_by':'SIGKILL','writer_reached_ready':ready,'results':results}

if __name__=='__main__':
    a=argparse.ArgumentParser()
    a.add_argument('--root',type=Path,default=Path(__file__).resolve().parent.parent)
    a.add_argument('--godot',type=Path,default=Path('/mnt/data/bin/Godot_v4.7.2-stable_linux.x86_64'))
    args=a.parse_args()
    evidence=[run(args.root,args.godot,41,4),run(args.root,args.godot,800000,6)]
    out=args.root/'reports/R4_M12_SIGKILL_MATRIX.json'
    out.write_text(json.dumps({'runs':evidence,'passed':all(x['passed'] for x in evidence)},indent=2)+'\n')
    for x in evidence:print('R4_M12_SIGKILL seed=%s screens=%s PASS=%s %s'%(x['seed'],x['screens'],x['passed'],x.get('results','')))
    sys.exit(0 if all(x['passed'] for x in evidence) else 1)
