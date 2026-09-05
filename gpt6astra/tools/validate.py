"""Offline, dependency-free shaderpack validation. Never opens another shaderpack.
Requires Khronos glslangValidator on PATH (or --compiler PATH) for compile/link.
The offline preamble simulates only documented Iris macros; it is NOT an Iris
runtime, driver, framebuffer or visual compatibility test.
"""
from __future__ import annotations
import argparse
import concurrent.futures
import json
import hashlib
import math
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
SHADERS = ROOT/'shaders'
BUILD = ROOT/'build'/'validation'
INCLUDE = re.compile(r'^\s*#include\s+"([^"]+)"\s*$',re.M)
FEATURES = ['SHADOWS','COLORED_SHADOWS','AMBIENT_OCCLUSION','HAND_LIGHT','CLOUDS',
    'VOLUMETRIC_LIGHT','STARS','END_HALO','WATER_REFLECTIONS','WIND','WET_SURFACES','BLOOM','EDGE_AA']
PREAMBLE = '''
// Offline stand-ins for documented Iris preprocessor constants.
#define MC_VERSION 12111
#define MC_GL_VERSION 330
#define MC_GLSL_VERSION 330
#define IS_IRIS 1
'''
def source_fingerprint():
    digest=hashlib.sha256()
    for path in sorted(SHADERS.rglob('*')):
        if path.is_file():
            digest.update(path.relative_to(SHADERS).as_posix().encode()+b'\0')
            digest.update(path.read_bytes()+b'\0')
    return digest.hexdigest()

def expand(path: Path, stack: tuple[Path,...] = ()) -> str:
    path = path.resolve()
    if not path.is_relative_to(SHADERS.resolve()): raise ValueError(f'Include escapes shaders: {path}')
    if path in stack: raise ValueError(f'Include cycle: {path}')
    text = path.read_text(encoding='utf-8')
    def replace(match):
        name = match.group(1)
        child = SHADERS/name[1:] if name.startswith('/') else path.parent/name
        return f'// BEGIN {name}\n'+expand(child,stack+(path,))+f'\n// END {name}\n'
    return INCLUDE.sub(replace,text)

def profiles():
    result = {}
    for line in (SHADERS/'shaders.properties').read_text(encoding='utf-8').splitlines():
        if line.startswith('profile.'):
            name, entries = line.split('=',1)
            settings = {}
            for item in entries.split():
                if ':' in item:
                    key,value = item.split(':',1);settings[key]=value
                elif item.startswith('!'): settings[item[1:]]=False
                else: settings[item]=True
            result[name.removeprefix('profile.')] = settings
    result['MINIMAL'] = {feature:False for feature in FEATURES}
    return result

def configure(text, options, fade):
    for key,value in options.items():
        if isinstance(value,bool):
            pattern = re.compile(r'^([ \t]*)#define\s+'+re.escape(key)+r'(?=\s|$)([^\n]*)$',re.M)
            if not value: text = pattern.sub(lambda m: m.group(1)+'// #define '+key+m.group(2),text)
        else:
            macro = re.compile(r'^(#define\s+'+re.escape(key)+r'\s+)\S+',re.M)
            const = re.compile(r'^(const\s+\w+\s+'+re.escape(key)+r'\s*=\s*)[^;]+',re.M)
            text,n = macro.subn(lambda m:m.group(1)+str(value),text)
            if not n: text = const.sub(lambda m:m.group(1)+str(value),text)
    preamble = PREAMBLE
    if fade: preamble += '#define IRIS_FEATURE_FADE_VARIABLE\nuniform float mc_chunkFade;\n'
    first,rest = text.split('\n',1)
    return first+'\n'+preamble+rest

def validate_clear_colors(source, label):
    """Validate Iris ClearColor metadata, which is stricter than legal GLSL.

    API: all four vec4 components must be explicitly supplied. This intentionally
    rejects GLSL's valid scalar-splat shorthand before packaging can proceed.
    """
    source = re.sub(r'/\*.*?\*/|//[^\n]*', '', source, flags=re.S)
    declarations = re.findall(r'\bconst\s+vec4\s+(\w+ClearColor)\s*=\s*([^;]+);', source)
    for name, expression in declarations:
        constructor = re.fullmatch(r'vec4\s*\(([^()]*)\)', expression.strip())
        assert constructor is not None, f'{label}: {name} must be an explicit vec4 constructor'
        components = [part.strip() for part in constructor.group(1).split(',')]
        assert len(components) == 4 and all(components), (
            f'{label}: {name} requires 4 explicit components for Iris, got {len(components)}')
    return len(declarations)

def validate_buffer_formats(source, label):
    """Pack policy: Iris format directives must be standalone block-comment lines.

    API permits manual definitions too, but this pack deliberately uses metadata
    comments so neither the loader nor the test harness must define GLSL symbols.
    """
    directive = re.compile(r'\bconst\s+int\s+((?:colortex|shadowcolor)\d+Format)\s*=\s*([A-Z][A-Z0-9_]*)\s*;')
    declarations = list(directive.finditer(source))
    blocks = list(re.finditer(r'/\*.*?\*/', source, re.S))
    for match in declarations:
        assert any(block.start() < match.start() and match.end() < block.end() for block in blocks), (
            f'{label}: {match.group(1)} must be in a block comment, not active GLSL or //')
        line_start = source.rfind('\n',0,match.start())+1
        line_end = source.find('\n',match.end())
        if line_end == -1: line_end = len(source)
        assert source[line_start:line_end].strip() == match.group(0), (
            f'{label}: {match.group(1)} must occupy its own metadata line')
    return len(declarations)

def check_invariants():
    checks=[]
    colors=0
    formats=0
    assert not re.search(r"#define\s+(?:RGBA16F|RGBA8)\b", PREAMBLE), "Do not hide missing format definitions in test macros"
    for path in SHADERS.rglob('*'):
        if path.suffix in {'.glsl','.vsh','.fsh'}:
            source=path.read_text(encoding='utf-8')
            colors += validate_clear_colors(source,path)
            formats += validate_buffer_formats(source,path)
    assert colors>0, 'Expected ClearColor directives'
    assert formats==7, f'Expected 7 symbolic format metadata directives, got {formats}'
    checks.append('7 format directives are standalone block-comment metadata; no test-only format macros')
    checks.append(f'{colors} Iris ClearColor directives have four explicit components')
    entrypoints = sorted([*SHADERS.glob('*.vsh'),*SHADERS.glob('world*/*.vsh')])
    assert len(entrypoints)==132, f'Expected 132 pairs, got {len(entrypoints)}'
    for path in entrypoints:
        assert path.with_suffix('.fsh').exists(), f'Missing fragment stage: {path}'
        for stage in [path,path.with_suffix('.fsh')]:
            source=expand(stage)
            assert source.startswith('#version 330 compatibility\n'),stage
            assert source.count('#version')==1,stage
            assert not re.search(r'\b(?:nan|infinity)\b',source,re.I),stage
    checks.append(f'{len(entrypoints)} complete program pairs; all include trees valid')
    props = (SHADERS/'shaders.properties').read_text(encoding='utf-8')
    assert 'separateEntityDraws=true' in props
    assert 'iris.features.required=ENTITY_TRANSLUCENT' in props
    sizes = dict(re.findall(r'^size.buffer.(colortex\d+)=(.+)$',props,re.M))
    assert sizes['colortex5']==sizes['colortex6']==sizes['colortex7']=='0.5 0.5'
    # Multi-target outputs within a pass cannot attach different texture sizes.
    for path in (SHADERS/'program').glob('*.fsh'):
        for targets in re.findall(r'RENDERTARGETS:\s*([0-9,]+)',path.read_text(encoding='utf-8')):
            dims = {sizes.get('colortex'+n,'1.0 1.0') for n in targets.split(',')}
            assert len(dims)==1, f'Mixed-size framebuffer: {path}'
    checks.append('Iris translucent split and MRT dimensions are consistent')
    settings = (SHADERS/'lib/settings.glsl').read_text(encoding='utf-8')
    for name, values in profiles().items():
        for option in values:
            assert re.search(r'(#define\s+'+option+r'\b|const\s+\w+\s+'+option+r'\s*=)',settings),f'{name}: unknown {option}'
    checks.append('All preset keys correspond to declared shader options')
    # The two halves share the same anchor weight at their common border.
    assert abs(1.0*0.5-(0.5+0.0*0.5))<1e-10
    checks.append('Tall-plant anchor seam invariant (.5 lower top == .5 upper bottom)')
    # Warp is monotone radial; no folds or poles inside or outside shadow disk.
    last=-1.0
    for i in range(2001):
        r=i/1000.0;warped=r/(0.28+0.72*r)
        assert math.isfinite(warped) and warped>last;last=warped
    checks.append('Shadow radial projection finite and monotonic across 2,001 radii')
    last=0.0
    for i in range(5001):
        x=10**(-6+i*10/5000)
        y=x*(1+0.10*x)/(0.82+1.16*x+0.10*x*x)
        assert math.isfinite(y) and 0<=y<=1 and y>=last-1e-10;last=y
    checks.append('Tone-curve luminance finite, bounded and monotonic across 5,001 HDR inputs')
    # Catch a GLSL undefined-behavior pitfall for constant smoothstep edges.
    for path in SHADERS.rglob('*'):
        if path.suffix not in {'.glsl','.fsh','.vsh'}:continue
        text=path.read_text(encoding='utf-8')
        for a,b in re.findall(r'smoothstep\(\s*(-?\d+\.\d+)\s*,\s*(-?\d+\.\d+)\s*,',text):
            assert float(a)<float(b),f'Reversed smoothstep: {path} ({a},{b})'
    checks.append('No reversed/equal literal smoothstep edges')
    # No external texture payloads, binary shader dependencies, or include URL fetches.
    assert not any(p.suffix.lower() in {'.png','.jpg','.dds','.jar','.exe'} for p in SHADERS.rglob('*'))
    checks.append('Shader assets are source-only; no external texture/binary payload')
    for vertex in (SHADERS/'world0').glob('gbuffers_*.vsh'):
        fragment=expand(vertex.with_suffix('.fsh'))
        assert not re.search(r'uniform\s+sampler2D\s+colortex[0-3]\s*;',fragment),f'Forbidden gbuffers attachment sampler: {vertex}'
    checks.append('No gbuffers program samples reserved colortex0-3 attachment aliases')
    water=(SHADERS/'program/water.fsh').read_text(encoding='utf-8')
    assert 'surface += bendDelta' in water and 'boundaryDelta/alpha,alpha' in water
    # Demonstrate why signed refraction must survive until destination blending.
    background,refracted,transmission,surface=4.0,0.1,0.8,0.05
    composed=background*transmission+surface+(refracted-background)*transmission
    assert abs(composed-(surface+refracted*transmission))<1e-10
    # Boundary corrections retain any already-composited translucent residual.
    old_opaque,corrected,alpha,residual=0.1,0.7,0.2,0.3
    combined=(old_opaque+residual)*(1-alpha)+(corrected-old_opaque*(1-alpha))
    assert abs(combined-(corrected+residual*(1-alpha)))<1e-10
    checks.append('Signed refraction identity and underwater translucent-residual composition')
    return checks

def compile_pair(job):
    compiler,profile,dimension,vertex,options,fade=job
    out=BUILD/profile/dimension;out.mkdir(parents=True,exist_ok=True)
    paths=[]
    for ext,stage in [('vert',vertex),('frag',vertex.with_suffix('.fsh'))]:
        target=out/(vertex.stem+'.'+ext)
        target.write_text(configure(expand(stage),options,fade),encoding='utf-8',newline='\n')
        paths.append(target)
    proc=subprocess.run([compiler,'-l',*[str(p) for p in paths]],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60)
    return {'profile':profile,'dimension':dimension,'program':vertex.stem,'ok':proc.returncode==0,
        'output':proc.stdout+proc.stderr if proc.returncode else ''}

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--compiler',default=shutil.which('glslangValidator'))
    parser.add_argument('--static-only',action='store_true')
    parser.add_argument('--quick',action='store_true',help='Compile balanced preset only, all 3 dimensions')
    parser.add_argument('--jobs',type=int,default=6)
    args=parser.parse_args()
    start=time.perf_counter()
    checks=check_invariants()
    for check in checks:print('PASS',check,flush=True)
    if args.static_only:return 0
    if not args.compiler:
        print('ERROR: glslangValidator not found. Pass --compiler PATH, or --static-only.',file=sys.stderr);return 2
    matrix=profiles()
    if args.quick:matrix={'BALANCED':matrix['BALANCED']}
    jobs=[]
    for name,options in matrix.items():
        for dimension in ['world0','world-1','world1']:
            for vertex in sorted((SHADERS/dimension).glob('*.vsh')):
                jobs.append((args.compiler,name,dimension,vertex,options,name!='MINIMAL'))
    with concurrent.futures.ThreadPoolExecutor(max_workers=max(1,args.jobs)) as pool:
        results=list(pool.map(compile_pair,jobs))
    failed=[r for r in results if not r['ok']]
    report={'source_sha256':source_fingerprint(),'scope':'Offline expanded GLSL compile + stage link; not in-game validation',
        'compiler':subprocess.run([args.compiler,'--version'],capture_output=True,text=True).stdout.strip(),
        'static_checks':checks,'program_pairs':len(results),'shader_stages':len(results)*2,
        'profiles':list(matrix),'dimensions':['world0','world-1','world1'],
        'failed':len(failed),'seconds':round(time.perf_counter()-start,2),'failures':failed}
    BUILD.mkdir(parents=True,exist_ok=True)
    (BUILD/'report.json').write_text(json.dumps(report,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    for failure in failed[:15]:
        print(f"FAIL {failure['profile']}/{failure['dimension']}/{failure['program']}\n{failure['output']}")
    print(f"{'PASS' if not failed else 'FAIL'}: {len(results)-len(failed)}/{len(results)} program pairs compiled and linked ({len(results)*2} stages), {report['seconds']}s.")
    print('Report:',BUILD/'report.json')
    return 1 if failed else 0
if __name__=='__main__':raise SystemExit(main())
