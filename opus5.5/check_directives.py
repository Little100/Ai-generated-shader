# 检查预处理指令的配对情况, 找出缺失或多余的 #endif
# 这一步必须先做, 否则条件块会被静默破坏

import os
import re
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
SHADERS = os.path.join(ROOT, "shaders")

DIRECTIVE = re.compile(r'^\s*#\s*(if|ifdef|ifndef|elif|else|endif)\b(.*)$')


def check(path):
    depth = 0
    problems = []
    stack = []
    for number, line in enumerate(open(path, encoding="utf-8"), 1):
        m = DIRECTIVE.match(line)
        if not m:
            continue
        kind = m.group(1)
        if kind in ("if", "ifdef", "ifndef"):
            depth += 1
            stack.append((number, line.strip()))
        elif kind == "endif":
            if depth == 0:
                problems.append("%d 行多余的 #endif" % number)
            else:
                depth -= 1
                stack.pop()
        elif kind in ("else", "elif"):
            if depth == 0:
                problems.append("%d 行孤立的 #%s" % (number, kind))
    for number, text in stack:
        problems.append("%d 行缺少配对的 #endif -> %s" % (number, text))
    return problems


def main():
    bad = 0
    for base, _, files in os.walk(SHADERS):
        for name in sorted(files):
            if not name.endswith((".glsl", ".fsh", ".vsh")):
                continue
            path = os.path.join(base, name)
            problems = check(path)
            rel = os.path.relpath(path, SHADERS)
            if problems:
                bad += 1
                print("=== %s ===" % rel)
                for p in problems:
                    print("   " + p)
            else:
                print("配对正常 %s" % rel)
    print("\n有问题的文件: %d" % bad)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
