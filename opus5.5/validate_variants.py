# 遍历关键选项的每个取值, 确认所有宏组合都能通过编译
# 选项以 #define 形式存在于 settings.glsl, 这里直接在展开结果里替换

import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, ROOT)
import validate_glsl as V

# 需要遍历的选项及其取值
VARIANTS = {
    "shadowSamples": [4, 8, 12, 20, 32],
    "godraySteps": [8, 16, 24, 40, 64],
    "cloudSteps": [12, 18, 24, 36, 56],
    "DAPPLED_LIGHT": [0, 1],
    "CLOUD_SHADOW": [0, 1],
    "SSAO": [0, 1],
    "SP_CLOUDS": [0, 1],
    "VOLUMETRIC_FOG": [0, 1],
    "GOD_RAYS": [0, 1],
    "WATER_WAVES": [0, 1],
    "WATER_REFLECTION": [0, 1],
    "BLOOM": [0, 1],
    "TONEMAP_ACES": [0, 1],
}


def targets():
    out = []
    for base, _, files in os.walk(V.SHADERS):
        for name in files:
            if V.stage_of(name):
                out.append(os.path.join(base, name))
    return sorted(out)


def patch_define(source, name, value):
    # 只改定义行, 不改被引用的位置
    pattern = re.compile(r'(?m)^#define\s+' + re.escape(name) + r'\s+\S+')
    if not pattern.search(source):
        return None
    return pattern.sub("#define %s %s" % (name, value), source, count=1)


def main():
    files = targets()
    failures = 0
    checked = 0
    with tempfile.TemporaryDirectory() as tmp:
        for name, values in VARIANTS.items():
            for value in values:
                checked += 1
                for target in files:
                    stage = V.stage_of(os.path.basename(target))
                    source = V.prepare(target, stage == "vert")
                    patched = patch_define(source, name, value)
                    if patched is None:
                        continue
                    tmp_file = os.path.join(tmp, os.path.basename(target))
                    with open(tmp_file, "w", encoding="utf-8") as handle:
                        handle.write(patched)
                    result = subprocess.run(
                        [V.VALIDATOR, "-S", stage, tmp_file],
                        capture_output=True, text=True, encoding="utf-8", errors="replace",
                    )
                    output = (result.stdout or "") + (result.stderr or "")
                    if "ERROR" in output or result.returncode != 0:
                        failures += 1
                        print("失败 %s=%s -> %s" % (name, value, os.path.basename(target)))
                        for line in output.splitlines():
                            if "ERROR" in line:
                                print("   " + line.strip())
    print("\n共检查 %d 组选项, %d 个失败" % (checked, failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
