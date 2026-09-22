import os, re, sys, glob

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Starweave-Shaders", "shaders")

def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    text = re.sub(r"//[^\n]*", "", text)
    return text

def expand(path, seen=None, depth=0):
    if seen is None:
        seen = set()
    key = os.path.normcase(os.path.abspath(path))
    if key in seen:
        return ""
    seen.add(key)
    with open(path, "r", encoding="utf-8") as f:
        lines = f.readlines()
    out = []
    for line in lines:
        m = re.match(r'\s*#include\s+"(/[^"]+)"', line)
        if m:
            inc = os.path.join(ROOT, m.group(1).lstrip("/").replace("/", os.sep))
            if not os.path.isfile(inc):
                out.append("<<MISSING INCLUDE %s>>" % m.group(1))
            else:
                out.append(expand(inc, seen, depth + 1))
        else:
            out.append(line)
    return "".join(out)

errors = []
warnings = []

shader_files = []
for dirpath, dirnames, filenames in os.walk(ROOT):
    for name in filenames:
        if name.endswith((".vsh", ".fsh")):
            shader_files.append(os.path.join(dirpath, name))

for path in shader_files:
    rel = os.path.relpath(path, ROOT)
    raw = open(path, "r", encoding="utf-8").read()
    first = strip_comments(raw).strip().splitlines()
    first = [l for l in first if l.strip()]
    if not first or not first[0].startswith("#version 140"):
        errors.append("%s: #version 140 must be the first statement" % rel)
    if "<<MISSING INCLUDE" in expand(path):
        for m in re.findall(r"<<MISSING INCLUDE ([^>]+)>>", expand(path)):
            errors.append("%s: missing include %s" % (rel, m))

    text = strip_comments(expand(path))
    if text.count("{") != text.count("}"):
        errors.append("%s: unbalanced braces %d/%d" % (rel, text.count("{"), text.count("}")))
    if text.count("(") != text.count(")"):
        errors.append("%s: unbalanced parens %d/%d" % (rel, text.count("("), text.count(")")))

    uniforms = re.findall(r"\buniform\s+\w+\s+(\w+)\s*;", text)
    seen_u = {}
    for u in uniforms:
        if u in seen_u:
            errors.append("%s: duplicate uniform %s" % (rel, u))
        seen_u[u] = True

    if path.endswith(".fsh"):
        uses_fragdata = "gl_FragData" in text
        has_db = "DRAWBUFFERS" in raw
        if uses_fragdata and not has_db and not rel.endswith("final.fsh"):
            errors.append("%s: uses gl_FragData but no DRAWBUFFERS comment" % rel)
        if not uses_fragdata and has_db:
            warnings.append("%s: DRAWBUFFERS without gl_FragData" % rel)

programs = {}
for path in shader_files:
    rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
    base = rel[:-4]
    prog, ext = base, "." + rel[-3:]
    programs.setdefault(prog, {})[ext] = path

for prog, parts in sorted(programs.items()):
    if ".vsh" not in parts or ".fsh" not in parts:
        errors.append("program %s missing %s" % (prog, ".fsh" if ".vsh" in parts else ".vsh"))
        continue
    vrel = os.path.relpath(parts[".vsh"], ROOT)
    frel = os.path.relpath(parts[".fsh"], ROOT)
    vt = strip_comments(expand(parts[".vsh"]))
    ft = strip_comments(expand(parts[".fsh"]))
    v_out = dict(re.findall(r"\bout\s+(\w+)\s+(\w+)\s*;", vt))
    f_in = dict(re.findall(r"\bin\s+(\w+)\s+(\w+)\s*;", ft))
    for name, typ in f_in.items():
        if name not in v_out:
            if name in ("gl_FragCoord",):
                continue
            errors.append("%s: fsh input %s %s has no matching vsh output" % (frel, typ, name))
        elif v_out[name] != typ:
            errors.append("%s: varying %s type mismatch vsh=%s fsh=%s" % (prog, name, v_out[name], typ))

props = open(os.path.join(ROOT, "shaders.properties"), "r", encoding="utf-8").read()
for pf in ("shaders.properties", "block.properties"):
    raw_b = open(os.path.join(ROOT, pf), "rb").read()
    try:
        raw_b.decode("ascii")
    except UnicodeDecodeError:
        errors.append("%s: must be pure ASCII, Iris properties preprocessor rejects non-ASCII" % pf)
opts = set()
scan_files = list(shader_files)
for dirpath, dirnames, filenames in os.walk(ROOT):
    for name in filenames:
        if name.endswith(".glsl"):
            scan_files.append(os.path.join(dirpath, name))
for path in scan_files:
    raw = open(path, "r", encoding="utf-8").read()
    opts.update(re.findall(r"^\s*#define\s+([A-Z][A-Z0-9_]*)\s*(?://|$)", raw, flags=re.M))
    opts.update(re.findall(r"^\s*#define\s+([A-Z][A-Z0-9_]*)\s+\S+\s*//", raw, flags=re.M))
for line in props.splitlines():
    if line.startswith("screen") or line.startswith("profile.") or line.startswith("sliders"):
        rhs = line.split("=", 1)[1] if "=" in line else ""
        for tok in rhs.split():
            if tok.startswith("[") or tok.startswith("<") or tok == "*":
                continue
            t = tok.lstrip("!")
            t = t.split(":")[0]
            if re.match(r"^[A-Z][A-Z0-9_]*$", t) and t not in opts:
                warnings.append("shaders.properties references option not found in shaders: %s" % t)

print("checked %d shader files, %d programs" % (len(shader_files), len(programs)))
for w in warnings:
    print("WARN:", w)
for e in errors:
    print("ERROR:", e)
print("RESULT:", "FAIL" if errors else "PASS")
sys.exit(1 if errors else 0)
