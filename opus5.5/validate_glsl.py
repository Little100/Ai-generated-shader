# Iris 着色器离线校验
# 关键在于忠实还原 Iris 的预处理行为: include 展开不去重, 条件编译按宏求值
# 只有这样才能复现 "库文件被重复展开导致函数重复定义" 这类真实错误

import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
SHADERS = os.path.join(ROOT, "shaders")
VALIDATOR = os.environ.get("GLSLANG", r"C:\Users\littI\AppData\Local\Temp\glslang\bin\glslang.exe")

INCLUDE_RE = re.compile(r'^\s*#\s*include\s+"([^"]+)"\s*$')
DEFINE_RE = re.compile(r'^\s*#\s*define\s+(\w+)(?:\s+(.*))?$')
COND_RE = re.compile(r'^\s*#\s*(if|ifdef|ifndef|elif|else|endif)\b(.*)$')

# Iris 的缓冲区声明只在 Iris 预处理阶段有意义, 交给 glslang 前摘掉
META_DECL_RE = re.compile(
    r'^\s*const\s+(?:int|bool|vec4)\s+(?:colortex|shadowcolor|shadowtex)\d+'
    r'(?:Format|Clear|ClearColor)\s*=.*$',
    re.M,
)


def read(path):
    with open(path, "r", encoding="utf-8") as handle:
        return handle.read()


def eval_condition(expr, macros):
    # 把宏替换成字面量后求值, 支持 == != && || ! 与整数比较
    def replace(match):
        name = match.group(0)
        if name in macros:
            return str(macros[name])
        return "0"

    text = re.sub(r'\b[A-Za-z_]\w*\b', replace, expr)
    # 去掉 GLSL 风格的后缀, 统一成 Python 能算的写法
    text = text.replace('&&', ' and ').replace('||', ' or ')
    text = re.sub(r'!(?!=)', ' not ', text)
    try:
        return bool(eval(text, {"__builtins__": {}}, {}))
    except Exception:
        # 无法求值时按未定义处理, 与 C 预处理器一致
        return False


def preprocess(path, macros=None, stack=None):
    # 展开 include 并逐行处理条件编译, 不做任何去重
    if macros is None:
        macros = {}
    if stack is None:
        stack = []
    if len(stack) > 64:
        raise RuntimeError("include 递归过深: " + path)

    out = []
    # 条件栈元素为 (当前分支是否生效, 是否已经命中过某个分支)
    conditions = []

    def active():
        return all(item[0] for item in conditions)

    for line in read(path).splitlines():
        include = INCLUDE_RE.match(line)
        if include:
            if active():
                target = os.path.join(SHADERS, include.group(1).lstrip("/").replace("/", os.sep))
                if not os.path.isfile(target):
                    raise FileNotFoundError("include 找不到: " + include.group(1))
                out.append(preprocess(target, macros, stack + [path]))
            continue

        cond = COND_RE.match(line)
        if cond:
            kind, rest = cond.group(1), cond.group(2).strip()
            if kind in ("if", "ifdef", "ifndef"):
                if kind == "ifdef":
                    value = rest in macros
                elif kind == "ifndef":
                    value = rest not in macros
                else:
                    value = eval_condition(rest, macros)
                conditions.append([bool(value), bool(value)])
            elif kind == "elif":
                if conditions:
                    taken = conditions[-1][1]
                    value = (not taken) and eval_condition(rest, macros)
                    conditions[-1] = [bool(value), taken or bool(value)]
            elif kind == "else":
                if conditions:
                    taken = conditions[-1][1]
                    conditions[-1] = [not taken, True]
            elif kind == "endif":
                if conditions:
                    conditions.pop()
            continue

        if not active():
            continue

        define = DEFINE_RE.match(line)
        if define:
            # 所有宏都要登记, 包含守卫必须进入宏表否则 #ifndef 永远为真
            macros[define.group(1)] = (define.group(2) or "").strip()

        out.append(line)

    if conditions:
        raise RuntimeError("条件编译未闭合: " + path)
    return "\n".join(out)


def prepare(path, is_vertex):
    body = preprocess(path)
    body = re.sub(r'^\s*#version[^\n]*\n', "", body)
    body = re.sub(r'/\*\s*RENDERTARGETS.*?\*/', "", body, flags=re.S)
    body = META_DECL_RE.sub("", body)
    return "#version 330 compatibility\n" + body


def stage_of(name):
    if name.endswith(".vsh"):
        return "vert"
    if name.endswith(".fsh"):
        return "frag"
    return None


def targets():
    out = []
    for base, _, files in os.walk(SHADERS):
        for name in files:
            if stage_of(name):
                out.append(os.path.join(base, name))
    return sorted(out)


def main():
    if not os.path.isfile(VALIDATOR):
        print("找不到 glslangValidator, 请设置 GLSLANG 环境变量")
        return 2

    files = targets()
    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        for target in files:
            name = os.path.basename(target)
            stage = stage_of(name)
            try:
                source = prepare(target, stage == "vert")
            except (FileNotFoundError, RuntimeError) as error:
                failures += 1
                print("\n==== 失败 %s ====" % name)
                print("   " + str(error))
                continue
            tmp_file = os.path.join(tmp, name)
            with open(tmp_file, "w", encoding="utf-8") as handle:
                handle.write(source)
            result = subprocess.run(
                [VALIDATOR, "-S", stage, tmp_file],
                capture_output=True, text=True, encoding="utf-8", errors="replace",
            )
            output = (result.stdout or "") + (result.stderr or "")
            if "ERROR" in output or result.returncode != 0:
                failures += 1
                print("\n==== 失败 %s ====" % name)
                for line in output.splitlines():
                    stripped = line.strip()
                    if stripped and not stripped.startswith("glslang"):
                        print("   " + stripped)
            else:
                print("通过 %s" % name)

    print("\n合计 %d 个程序, %d 个失败" % (len(files), failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
