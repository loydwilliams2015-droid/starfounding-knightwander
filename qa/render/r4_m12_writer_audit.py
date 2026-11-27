#!/usr/bin/env python3
"""Append-only R4-M12 dependency audit; never rewrites or removes legacy QA files.

Only maps the checked-in project scripting surface. This is NOT a guarantee that
arbitrary same-process Godot scripts cannot import or bypass older writer classes.
"""
from pathlib import Path
import argparse, hashlib, json, re, sys

LEGACY_MUTABLE = {
    'r4_m04_checkpoint.gd': 'v1 rotating checkpoint journal; direct commit',
    'r4_m05_journal.gd': 'extended journal; direct commit',
    'r4_m06_transaction.gd': 'original direct transaction commit',
    'r4_m08_outbox.gd': 'outbox ACK writer and owner-lock',
    'r4_m09_coordinator.gd': 'opt-in checkpoint + ACK coordinator',
    'r4_m10_guarded_tx.gd': 'guarded TX writer with mutable local permit',
    'r4_m10_guarded_ack.gd': 'guarded ACK writer with mutable local permit',
    'r4_m10_coordinator.gd': 'gateway with internal permit setters',
    'r4_m11_provider.gd': 'recommended v1 public provider, not a sandbox',
}
FINAL_PROVIDER='r4_m12_provider.gd'
FINAL_MIGRATION='r4_m12_migration.gd'
FINAL_SINK='r4_m12_sandbox_sink.gd'
FUNC_RE=re.compile(r'^\s*func\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(',re.M)
MUTATE_RE=re.compile(r'\b(FileAccess\.open|DirAccess\.rename_absolute|DirAccess\.make_dir_absolute|DirAccess\.remove_absolute|\.store_string\s*\(|\.commit_from_actor\s*\(|\.acknowledge\s*\()')

def audit(root: Path)->dict:
    scripts=root/'scripts'
    rows=[]
    for f in sorted(scripts.rglob('*.gd')):
        source=f.read_text(encoding='utf-8')
        is_legacy=f.name in LEGACY_MUTABLE
        rows.append({
            'file':str(f.relative_to(root)),
            'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),
            'classification':('legacy-mutable-QA' if is_legacy else
                'R4-M12-public-provider' if f.name==FINAL_PROVIDER else
                'read-only-migration' if f.name==FINAL_MIGRATION else
                'in-memory-isolated-sink' if f.name==FINAL_SINK else 'other-QA'),
            'entrypoints':FUNC_RE.findall(source),
            'contains_mutation_pattern':bool(MUTATE_RE.search(source)),
            'risk_note':LEGACY_MUTABLE.get(f.name,''),
        })
    names={Path(row['file']).name for row in rows}
    errors=[]
    if not names.issuperset(set(LEGACY_MUTABLE)|{FINAL_PROVIDER,FINAL_MIGRATION,FINAL_SINK}):
        errors.append('missing known writer or R4-M12 file')
    provider=(scripts/FINAL_PROVIDER).read_text()
    migrate=(scripts/FINAL_MIGRATION).read_text()
    sink=(scripts/FINAL_SINK).read_text()
    if re.search(r'\b(FileAccess|DirAccess)\b',provider):errors.append('R4-M12 provider has direct filesystem API')
    if re.search(r'\b(FileAccess|DirAccess)\b',migrate):errors.append('read-only migration uses filesystem API')
    if re.search(r'\b(FileAccess|DirAccess)\b',sink):errors.append('isolated sink uses filesystem API')
    if 'request_gameplay_item' not in sink or 'request_gameplay_event' not in sink:
        errors.append('sink cannot explicitly reject real gameplay requests')
    if not all(k in provider for k in ['extends "res://scripts/r4_m11_provider.gd"','deliver_sandbox','v2_preview']):
        errors.append('provider interface incomplete')
    return {
        'milestone':'R4-M12', 'scope':'static source audit of standalone Godot QA',
        'script_count':len(rows), 'known_legacy_writer_count':len(LEGACY_MUTABLE),
        'legacy_write_surfaces_remaining':True,
        'public_documented_interface':'scripts/r4_m12_provider.gd',
        'production_wide_enforcement':False,
        'note':'Older QA mutable writer classes remain importable. Source audit is not a Godot security sandbox.',
        'errors':errors, 'passed':not errors, 'files':rows,
    }

if __name__=='__main__':
    p=argparse.ArgumentParser()
    p.add_argument('--root',type=Path,default=Path(__file__).resolve().parent.parent)
    p.add_argument('--output',type=Path,default=None)
    args=p.parse_args()
    summary=audit(args.root)
    destination=args.output or args.root/'reports/R4_M12_WRITER_ENTRYPOINT_AUDIT.json'
    destination.parent.mkdir(parents=True,exist_ok=True)
    destination.write_text(json.dumps(summary,indent=2,sort_keys=True)+'\n',encoding='utf-8')
    print('R4_M12_WRITER_AUDIT files=%s legacy=%s passed=%s errors=%s'%(
        summary['script_count'],summary['known_legacy_writer_count'],summary['passed'],len(summary['errors'])))
    sys.exit(0 if summary['passed'] else 1)
