"""Build a deterministic installable Tidelume ZIP from this workspace only.
No network access, no game-directory discovery, and no automatic installation.
A fresh full offline compile/link report is mandatory; native GPU evidence optional.
"""
from __future__ import annotations
import hashlib
import json
import zipfile
from pathlib import Path
from validate import ROOT, SHADERS, check_invariants, source_fingerprint
VERSION='0.1.2'
NAME=f'Tidelume-{VERSION}-Iris-1.21.11'
STAMP=(2026,9,5,0,0,0)

def main():
    check_invariants()
    fingerprint=source_fingerprint()
    report_path=ROOT/'build/validation/report.json'
    if not report_path.exists():raise SystemExit('Run python tools/validate.py before packaging.')
    report=json.loads(report_path.read_text(encoding='utf-8'))
    if (report.get('source_sha256')!=fingerprint or report.get('failed')!=0
        or report.get('program_pairs')!=396 or set(report.get('profiles',[]))!={'LOW','BALANCED','HIGH','MINIMAL'}):
        raise SystemExit('Missing, failed, incomplete, or stale full validation. Run python tools/validate.py.')
    sources=[ROOT/'README.md',ROOT/'LICENSE',*SHADERS.rglob('*'),*(ROOT/'docs').rglob('*'),*(ROOT/'tools').glob('*.py')]
    sources=sorted({p for p in sources if p.is_file()},key=lambda p:p.relative_to(ROOT).as_posix())
    for p in sources:
        if not p.resolve().is_relative_to(ROOT.resolve()):raise SystemExit(f'Source escapes workspace: {p}')
    files={p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}
    gpu_path=ROOT/'build/gpu/report.json';gpu=None
    if gpu_path.exists():
        candidate=json.loads(gpu_path.read_text(encoding='utf-8'))
        if candidate.get('source_sha256')==fingerprint and not candidate.get('failures'):
            gpu=candidate
    manifest={
        'name':'Tidelume / 汀光','version':VERSION,'target':'Minecraft Java 1.21.11 / matching Iris',
        'status':'First testable build; not validated inside Minecraft or Iris runtime',
        'source_sha256':fingerprint,'provenance':'Original source; API documentation only; no existing shaderpack used',
        'offline_validation':report,'native_gpu_validation':gpu,
        'minecraft_runtime_tested':False,'files_sha256':files,
    }
    manifest_bytes=(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n').encode('utf-8')
    dist=ROOT/'dist';dist.mkdir(exist_ok=True)
    archive=dist/(NAME+'.zip')
    with zipfile.ZipFile(archive,'w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as z:
        for path in sources:
            info=zipfile.ZipInfo(path.relative_to(ROOT).as_posix(),STAMP)
            info.compress_type=zipfile.ZIP_DEFLATED;info.external_attr=0o100644<<16
            z.writestr(info,path.read_bytes(),compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
        info=zipfile.ZipInfo('BUILD-MANIFEST.json',STAMP);info.external_attr=0o100644<<16
        z.writestr(info,manifest_bytes,compress_type=zipfile.ZIP_DEFLATED,compresslevel=9)
    with zipfile.ZipFile(archive) as z:
        names=z.namelist()
        assert z.testzip() is None,'Archive CRC validation failed'
        assert 'shaders/shaders.properties' in names
        assert 'shaders/world0/prepare.fsh' in names
        assert 'shaders/world-1/final.fsh' in names and 'shaders/world1/final.fsh' in names
        assert len(names)==len(set(names)),'Duplicate archive paths'
        assert not any(n.startswith('/') or '..' in Path(n).parts for n in names)
        for name,digest in files.items():assert hashlib.sha256(z.read(name)).hexdigest()==digest
    digest=hashlib.sha256(archive.read_bytes()).hexdigest()
    (dist/(NAME+'.sha256')).write_text(f'{digest}  {archive.name}\n',encoding='ascii')
    (dist/'BUILD-MANIFEST.json').write_bytes(manifest_bytes)
    print(f'Built {archive}\nFiles: {len(files)+1}; size: {archive.stat().st_size:,} bytes')
    print(f'SHA-256: {digest}')
    print(f'Offline certified: {report["program_pairs"]} program pairs / {report["shader_stages"]} stages')
    print(f'Fresh native GPU report: {"yes" if gpu else "no"}; Minecraft runtime validation: NOT RUN')
    return 0
if __name__=='__main__':raise SystemExit(main())
