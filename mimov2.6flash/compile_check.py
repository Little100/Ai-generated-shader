import os, re, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "Starweave-Shaders", "shaders")
OUT = os.path.join(HERE, "build_glsl")
GLSLANG = os.path.join(HERE, "glslang-tool", "bin", "glslang.exe")

ALL_OFF = "--all-off" in sys.argv
if ALL_OFF:
    OUT = os.path.join(HERE, "build_glsl_off")

RENAMES = [
    ("gl_FragData", "swc_FragData"),
    ("gl_MultiTexCoord0", "swc_MT0"),
    ("gl_MultiTexCoord1", "swc_MT1"),
    ("gl_ModelViewMatrix", "swc_MV"),
    ("gl_ProjectionMatrix", "swc_PJ"),
    ("gl_NormalMatrix", "swc_NM"),
    ("gl_TextureMatrix", "swc_TM"),
    ("gl_Vertex", "swc_Vertex"),
    ("gl_Normal", "swc_Normal"),
    ("gl_Color", "swc_Color"),
    ("ftransform", "swc_ftransform"),
]

PREAMBLE = """
in vec4 swc_Vertex;
in vec3 swc_Normal;
in vec4 swc_Color;
in vec4 swc_MT0;
in vec4 swc_MT1;
uniform mat4 swc_MV;
uniform mat4 swc_PJ;
uniform mat3 swc_NM;
uniform mat4 swc_TM[2];
out vec4 swc_FragData[8];
vec4 swc_ftransform(){ return swc_PJ * swc_MV * swc_Vertex; }
"""

TOGGLES = ["SHADOWS", "SSAO", "VOLUMETRICS", "CLOUD_SHADOWS", "BLOOM", "WAVING", "WATER_WAVES", "AURORA", "FXAA", "VIGNETTE"]

def expand(path, seen=None):
    if seen is None:
        seen = set()
    key = os.path.normcase(os.path.abspath(path))
    if key in seen:
        return ""
    seen.add(key)
    lines = open(path, "r", encoding="utf-8").readlines()
    out = []
    for line in lines:
        m = re.match(r'\s*#include\s+"(/[^"]+)"', line)
        if m:
            inc = os.path.join(ROOT, m.group(1).lstrip("/").replace("/", os.sep))
            if not os.path.isfile(inc):
                raise FileNotFoundError(m.group(1))
            out.append(expand(inc, seen))
        else:
            out.append(line)
    return "".join(out)

def apply_shim(text):
    if ALL_OFF:
        for t in TOGGLES:
            text = re.sub(r'^\s*#define\s+%s\s*(//.*)?$' % t, r'// \g<0>', text, flags=re.M)
    pattern = re.compile("|".join(re.escape(k) for k, _ in RENAMES))
    mapping = dict(RENAMES)
    lines = text.splitlines(keepends=True)
    out = []
    injected = False
    for line in lines:
        stripped = line.lstrip()
        if not injected and stripped.startswith("#version"):
            out.append(line)
            out.append(PREAMBLE)
            injected = True
            continue
        if stripped.startswith("#") and "include" not in stripped:
            out.append(line)
            continue
        out.append(pattern.sub(lambda m: mapping[m.group(0)], line))
    return "".join(out)

os.makedirs(OUT, exist_ok=True)
jobs = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    for name in filenames:
        if name.endswith((".vsh", ".fsh")):
            src = os.path.join(dirpath, name)
            rel = os.path.relpath(src, ROOT).replace(os.sep, "__")
            stage = "vert" if name.endswith(".vsh") else "frag"
            dst = os.path.join(OUT, rel[:-4] + "." + stage)
            text = apply_shim(expand(src))
            open(dst, "w", encoding="utf-8").write(text)
            jobs.append((src, dst, stage))

fail = 0
results = []
for src, dst, stage in jobs:
    p = subprocess.run([GLSLANG, "-S", stage, dst], capture_output=True, encoding="utf-8", errors="replace")
    if p.returncode != 0:
        fail += 1
        first = (p.stdout + p.stderr).strip().splitlines()
        results.append((os.path.relpath(src, ROOT), first[:14]))

label = "all-off" if ALL_OFF else "default"
print("[%s] compiled %d files, %d failed" % (label, len(jobs), fail))
for rel, lines in results:
    print("====", rel)
    for l in lines:
        print("   ", l)
sys.exit(1 if fail else 0)
