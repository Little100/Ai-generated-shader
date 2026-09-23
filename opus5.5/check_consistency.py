# 静态一致性检查, 找出定义了却没被使用的选项, 以及缓冲区与槽位的对不上的地方

import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SHADERS = os.path.join(ROOT, "shaders")


def read(path):
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def main():
    settings = read(os.path.join(SHADERS, "lib", "settings.glsl"))
    props = read(os.path.join(SHADERS, "shaders.properties"))
    blocks = read(os.path.join(SHADERS, "block.properties"))

    # 收集所有程序与库的源码
    sources = {}
    for base, _, files in os.walk(SHADERS):
        for name in files:
            if name.endswith((".glsl", ".fsh", ".vsh")):
                sources[os.path.join(base, name)] = read(os.path.join(base, name))

    # 库之外的代码
    def body_of(path):
        text = sources[path]
        return re.sub(r'(?m)^#include[^\n]*\n', '', text)

    consumers = {p: body_of(p) for p in sources}
    joined = "\n".join(consumers.values())

    # 选项名
    options = []
    for line in settings.splitlines():
        m = re.match(r'\s*(?:#define|const\s+\w+)\s+(\w+)', line)
        if m and not m.group(1).startswith("KOMOREBI_"):
            options.append(m.group(1))

    unused = []
    for name in options:
        # 在库与程序里查找引用, 排除定义行本身
        uses = 0
        for path, text in consumers.items():
            if path.endswith("settings.glsl"):
                continue
            uses += len(re.findall(r'\b' + re.escape(name) + r'\b', text))
        if uses == 0:
            unused.append(name)

    print("=== 未被任何代码使用的选项 ===")
    if unused:
        for name in unused:
            print("   " + name)
    else:
        print("   无")

    # 选项是否出现在 shaders.properties 的 screen 或 profile 中
    print("\n=== 未出现在 shaders.properties 的选项 ===")
    missing = [n for n in options if n not in props]
    if missing:
        for name in missing:
            print("   " + name)
    else:
        print("   无")

    # 槽位编号与 block.properties 的对应
    print("\n=== 材质槽与 block.properties 编号 ===")
    slot_defs = dict(re.findall(r'#define\s+(SLOT_\w+)\s+(\d+)', read(os.path.join(SHADERS, "lib", "math.glsl"))))
    declared = set(re.findall(r'(?m)^block\.(\d+)', blocks))
    for name, value in sorted(slot_defs.items(), key=lambda kv: int(kv[1])):
        if name in ("SLOT_NONE", "SLOT_ENTITY"):
            continue
        mark = "已声明" if value in declared else "缺失"
        print("   %-16s = %-4s %s" % (name, value, mark))
    for value in sorted(declared, key=int):
        if value not in slot_defs.values():
            print("   block.%s 在代码里没有对应槽位" % value)

    # 缓冲区读写的一致性
    print("\n=== 各 colortex 的读取情况 ===")
    for index in range(8):
        name = "colortex%d" % index
        reads = sum(len(re.findall(r'texture2D\(\s*' + name + r'\b', t)) for t in consumers.values())
        writes = 0
        for path, text in consumers.items():
            for m in re.finditer(r'RENDERTARGETS:([^*]*)\*/', text):
                if str(index) in [x.strip() for x in m.group(1).split(",")]:
                    writes += 1
        print("   %-10s 读取 %-3d 写入目标 %d 处" % (name, reads, writes))

    return 0


if __name__ == "__main__":
    sys.exit(main())
