"""Validate Iris shaderpack GLSL sources with glslangValidator.

Expands #include directives the way Iris does, compiles each program with the
correct shader stage, then translates the reported line numbers back to the
original file and line so failures point at real code.

With --sweep it also recompiles everything once per option configuration, which
is the only way to catch a branch that only exists at an option value nobody
happens to use by default.
"""

import argparse
import re
import subprocess
import sys
import tempfile
from pathlib import Path

SHADERS_DIR_NAME = "shaders"
CONFIG_RELATIVE_PATH = "lib/config.glsl"

INCLUDE_RE = re.compile(r'^\s*#include\s+["<]([^">]+)[">]')
VERSION_RE = re.compile(r'^\s*#version\b')
DIAG_RE = re.compile(r"^(ERROR|WARNING):\s*\d+:(\d+):")

# a numeric option carries its allowed values in a bracket list in the comment
NUMERIC_OPTION_RE = re.compile(r"^#define\s+(\w+)\s+(\S+)\s*//\s*\[([^\]]*)\]")
BOOLEAN_OPTION_ON_RE = re.compile(r"^#define\s+(\w+)\s*(?://.*)?$")
BOOLEAN_OPTION_OFF_RE = re.compile(r"^//\s*#define\s+(\w+)\s*$")

STAGE_BY_SUFFIX = {
    ".vsh": "vert",
    ".fsh": "frag",
    ".gsh": "geom",
    ".csh": "comp",
}


class IncludeError(Exception):
    pass


def read_pack_options(shaders_dir):
    """Return the numeric and boolean options declared in the config library."""
    text = (shaders_dir / CONFIG_RELATIVE_PATH).read_text(encoding="utf-8")

    numeric = {}
    boolean = {}
    for line in text.splitlines():
        match = NUMERIC_OPTION_RE.match(line)
        if match:
            name, default, values = match.groups()
            numeric[name] = (default, values.split())
            continue

        match = BOOLEAN_OPTION_OFF_RE.match(line)
        if match:
            boolean[match.group(1)] = False
            continue

        match = BOOLEAN_OPTION_ON_RE.match(line)
        if match and "[" not in line:
            boolean[match.group(1)] = True

    return numeric, boolean


def apply_overrides(text, overrides):
    """Rewrite the option lines in the config library for a sweep run."""
    out = []
    for line in text.splitlines():
        numeric = NUMERIC_OPTION_RE.match(line)
        if numeric and numeric.group(1) in overrides:
            name = numeric.group(1)
            out.append(f"#define {name} {overrides[name]} // [{numeric.group(3)}]")
            continue

        off = BOOLEAN_OPTION_OFF_RE.match(line)
        if off and off.group(1) in overrides:
            name = off.group(1)
            out.append(f"#define {name}" if overrides[name] else line)
            continue

        on = BOOLEAN_OPTION_ON_RE.match(line)
        if on and "[" not in line and on.group(1) in overrides:
            name = on.group(1)
            out.append(line if overrides[name] else f"// #define {name}")
            continue

        out.append(line)
    return "\n".join(out)


def expand_includes(path, shaders_dir, stack=None, lines=None, origin=None, overrides=None):
    """Inline #include directives, recording where each output line came from."""
    stack = stack or []
    lines = lines if lines is not None else []
    origin = origin if origin is not None else []
    overrides = overrides or {}

    if path in stack:
        chain = " -> ".join(p.name for p in stack + [path])
        raise IncludeError(f"circular include: {chain}")

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise IncludeError(f"{path} is not valid UTF-8: {exc}") from exc

    if overrides and path == (shaders_dir / CONFIG_RELATIVE_PATH):
        text = apply_overrides(text, overrides)

    for lineno, line in enumerate(text.splitlines(), start=1):
        match = INCLUDE_RE.match(line)
        if not match:
            lines.append(line)
            origin.append((path, lineno))
            continue

        raw = match.group(1)
        # a leading slash means relative to the shaders/ directory, which is how
        # Iris resolves includes
        target = (shaders_dir / raw.lstrip("/")) if raw.startswith("/") else (path.parent / raw)
        target = target.resolve()

        if not target.exists():
            raise IncludeError(f"{path.name}:{lineno} include not found: {raw}")
        if shaders_dir not in target.parents and target != shaders_dir:
            raise IncludeError(f"{path.name}:{lineno} include escapes shaders dir: {raw}")

        expand_includes(target, shaders_dir, stack + [path], lines, origin, overrides)

    return lines, origin


def build_translation_unit(lines, origin, program):
    """Keep #version first, as glsl requires, and keep the map in step."""
    for idx, line in enumerate(lines):
        if VERSION_RE.match(line):
            return lines, origin
    return ["#version 330 compatibility"] + lines, [(program, 0)] + origin


def translate(output, origin, tmp_path):
    """Rewrite compiler diagnostics to point at the original sources."""
    translated = []
    for line in output.splitlines():
        stripped = line.strip()
        match = DIAG_RE.match(stripped)
        if match and stripped.startswith(("ERROR", "WARNING")):
            index = int(match.group(2)) - 1
            if 0 <= index < len(origin):
                source, source_line = origin[index]
                line = line.replace(f":{match.group(2)}:", f":{source.name}:{source_line}:", 1)
        translated.append(line.replace(str(tmp_path), ""))
    return translated


def validate_file(path, shaders_dir, glslang, overrides=None, verbose=False):
    stage = STAGE_BY_SUFFIX.get(path.suffix.lower())
    if stage is None:
        return None

    try:
        lines, origin = expand_includes(path, shaders_dir, overrides=overrides)
    except IncludeError as exc:
        return f"INCLUDE ERROR: {exc}"

    lines, origin = build_translation_unit(lines, origin, path)

    with tempfile.TemporaryDirectory() as tmp:
        tmp_path = Path(tmp) / (path.stem + path.suffix)
        tmp_path.write_text("\n".join(lines) + "\n", encoding="utf-8")
        proc = subprocess.run(
            [glslang, "-S", stage, str(tmp_path)],
            capture_output=True,
            text=True,
        )

    if proc.returncode == 0:
        return ""

    output = (proc.stdout or "") + (proc.stderr or "")
    translated = translate(output, origin, tmp_path)
    if verbose:
        return "\n".join(translated)
    return "\n".join(line for line in translated if "ERROR" in line or "WARNING" in line)


def discover_programs(shaders_dir):
    found = []
    for pattern in ("*.vsh", "*.fsh", "*.gsh", "*.csh"):
        found.extend(sorted(shaders_dir.glob(pattern)))
    return found


def sweep_configurations(shaders_dir):
    """One configuration per interesting option setting."""
    numeric, boolean = read_pack_options(shaders_dir)

    configs = [("defaults", {})]

    low = {name: values[0] for name, (_, values) in numeric.items() if values}
    high = {name: values[-1] for name, (_, values) in numeric.items() if values}
    configs.append(("all options at their lowest", low))
    configs.append(("all options at their highest", high))

    for name, default in boolean.items():
        configs.append((f"{name} {'on' if not default else 'off'}", {name: not default}))

    return configs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("pack", nargs="?", default=None)
    parser.add_argument("--glslang", default="glslangValidator")
    parser.add_argument("--sweep", action="store_true",
                        help="also compile every option configuration")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    pack_root = Path(args.pack) if args.pack else Path(__file__).resolve().parents[1] / "Skyweave"
    # resolve up front: the include check compares against resolved paths, so a
    # relative argument would otherwise reject every include
    pack_root = pack_root.resolve()
    shaders_dir = pack_root if pack_root.name == SHADERS_DIR_NAME else pack_root / SHADERS_DIR_NAME

    if not shaders_dir.is_dir():
        print(f"no shaders directory at {shaders_dir}", file=sys.stderr)
        return 2

    programs = discover_programs(shaders_dir)
    if not programs:
        print(f"no shader programs found in {shaders_dir}", file=sys.stderr)
        return 2

    configs = sweep_configurations(shaders_dir) if args.sweep else [("defaults", {})]

    total_failed = 0
    for label, overrides in configs:
        print(f"--- {label} ---")
        failed = 0
        for program in programs:
            result = validate_file(program, shaders_dir, args.glslang, overrides, args.verbose)
            if result is None:
                continue
            if result != "":
                failed += 1
                print(f"  FAIL {program.relative_to(pack_root)}")
                print("\n".join(f"       {line}" for line in result.splitlines()))

        print(f"  {len(programs) - failed}/{len(programs)} compiled")
        total_failed += failed

    print(f"\n{'all configurations compiled' if total_failed == 0 else f'{total_failed} failures'}")
    return 1 if total_failed else 0


if __name__ == "__main__":
    sys.exit(main())
