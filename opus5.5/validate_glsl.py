# 把 Iris 形式的 GLSL 展开成单个文件后交给 glslangValidator 编译, 用于交付前自检
# 关键点在于 Iris 的着色器大量依赖固定管线内置量, 这里按需要合成兼容声明

import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.abspath(__file__))
SHADERS = os.path.join(ROOT, "shaders")
VALIDATOR = os.environ.get("GLSLANG", r"C:\Users\littI\AppData\Local\Temp\glslang\bin\glslang.exe")

INCLUDE_RE = re.compile(r'^\s*#include\s+"([^"]+)"\s*$')

# 各程序需要补出的内置量, 兼容模式下这些由 OpenGL 固定管线提供
GEOMETRY_DECLS = """
in vec3 gl_Normal;
in vec4 gl_Vertex;
in vec4 gl_Color;
in vec4 gl_MultiTexCoord0;
in vec4 gl_MultiTexCoord1;
in vec4 gl_MultiTexCoord2;
uniform mat4 gl_ModelViewMatrix;
uniform mat4 gl_ProjectionMatrix;
uniform mat4 gl_ModelViewProjectionMatrix;
uniform mat3 gl_NormalMatrix;
uniform mat4 gl_TextureMatrix[8];
uniform vec4 gl_FragCoord;
"""

FRAGMENT_DECLS = """
uniform vec4 gl_FragCoord;
out vec4 gl_FragData[16];
out vec4 gl_FragColor;
"""

VERTEX_DECLS = """
in vec3 gl_Normal;
in vec4 gl_Vertex;
in vec4 gl_Color;
in vec4 gl_MultiTexCoord0;
in vec4 gl_MultiTexCoord1;
in vec4 gl_MultiTexCoord2;
uniform mat4 gl_ModelViewMatrix;
uniform mat4 gl_ProjectionMatrix;
uniform mat4 gl_ModelViewProjectionMatrix;
uniform mat3 gl_NormalMatrix;
uniform mat4 gl_TextureMatrix[8];
out vec4 gl_Position;
"""

# 顶点属性由 Iris 提供, 只在 gbuffers 与 shadow 中可用
ATTRIBUTE_DECLS = """
in vec4 at_tangent;
in vec4 at_midBlock;
in vec2 mc_Entity;
in vec2 mc_midTexCoord;
"""


def expand(path, seen=None, is_vertex=False):
    # 递归展开 include, 同一文件只展开一次, 与 GLSL 的 include 守卫行为一致
    if seen is None:
        seen = set()
    real = os.path.normpath(path)
    if real in seen:
        return ""
    seen.add(real)

    with open(path, "r", encoding="utf-8") as handle:
        text = handle.read()

    out_lines = []
    for line in text.splitlines():
        match = INCLUDE_RE.match(line)
        if match:
            target = os.path.join(SHADERS, match.group(1).lstrip("/").replace("/", os.sep))
            out_lines.append(expand(target, seen, is_vertex))
        else:
            out_lines.append(line)
    return "\n".join(out_lines)


def prepare(path, is_vertex):
    body = expand(path)
    # 版本声明必须留在首行
    body = re.sub(r'^\s*#version[^\n]*\n', "", body)
    # 渲染目标注释只是元数据, 编译前抹掉
    body = re.sub(r'/\*\s*RENDERTARGETS.*?\*/', "", body, flags=re.S)
    prefix = "#version 330 compatibility\n"
    if is_vertex:
        prefix += VERTEX_DECLS
        prefix += ATTRIBUTE_DECLS
    else:
        prefix += FRAGMENT_DECLS
    return prefix + body


def stage_of(name):
    if name.endswith(".vsh"):
        return "vert"
    if name.endswith(".fsh"):
        return "frag"
    return None


def main():
    if not os.path.isfile(VALIDATOR):
        print("找不到 glslangValidator, 请设置 GLSLANG 环境变量")
        return 2

    targets = []
    for base, _, files in os.walk(SHADERS):
        for name in files:
            if stage_of(name):
                targets.append(os.path.join(base, name))
    targets.sort()

    failures = 0
    with tempfile.TemporaryDirectory() as tmp:
        for target in targets:
            name = os.path.basename(target)
            stage = stage_of(name)
            source = prepare(target, stage == "vert")
            # glslang 依据扩展名判断阶段
            tmp_file = os.path.join(tmp, name)
            with open(tmp_file, "w", encoding="utf-8") as handle:
                handle.write(source)
            result = subprocess.run(
                [VALIDATOR, tmp_file],
                capture_output=True,
                text=True,
                encoding="utf-8",
                errors="replace",
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

    print("\n合计 %d 个程序, %d 个失败" % (len(targets), failures))
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
