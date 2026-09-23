// 程序本体的唯一入口, 只需 #include "/lib/common.glsl" 即可获得全部库
// 包含顺序即依赖顺序, 每个库都只使用它上方已经定义的内容
// settings 选项, buffers 缓冲区格式, uniforms 变量声明
// math 常数与工具, noise 噪声, atmosphere 天空与光源, material 材质
// water 水面, shadow 阴影, lighting 光照, sky 天空, clouds 云, util 工具
#include "/lib/settings.glsl"
#include "/lib/buffers.glsl"
#include "/lib/uniforms.glsl"
#include "/lib/math.glsl"
#include "/lib/noise.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/material.glsl"
#include "/lib/water.glsl"
#include "/lib/shadow.glsl"
#include "/lib/lighting.glsl"
#include "/lib/sky.glsl"
#include "/lib/clouds.glsl"
#include "/lib/util.glsl"
