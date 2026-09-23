// 所有 uniform 声明集中在此, 它不依赖任何其它库
// 缓冲区约定
// colortex1 法线八面体编码 + 材质槽
// colortex2 光照贴图 + 自发光 + 不透明度
// colortex3 粗糙度 + 金属度 + 朝向 + 透光
// colortex4 辅助通道, 天光, 遮蔽, 材质槽, 透光
// colortex5 云的散射与不透明度, 之后转为泛光
// colortex6 泛光结果
// colortex7 反照率

// 矩阵
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 shadowModelView;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowProjectionInverse;

// 相机与玩家
uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform float eyeAltitude;
uniform vec3 relativeEyePosition;
uniform int isEyeInWater;
uniform int frameCounter;
uniform float frameTime;
uniform float frameTimeCounter;

// 时间与天体
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 shadowLightPosition;
uniform float sunAngle;
uniform float shadowAngle;
uniform int moonPhase;
uniform int worldTime;

// 天气与生物群系
uniform float rainStrength;
uniform float wetness;
uniform float thunderStrength;
uniform int biome;
uniform float temperature;
uniform float rainfall;
uniform vec2 eyeBrightness;
uniform vec2 eyeBrightnessSmooth;

// 屏幕
uniform float viewWidth;
uniform float viewHeight;
uniform float aspectRatio;
uniform int heldBlockLightValue;

// 维度属性, 下界有岩顶而无天光, 末地两者皆无
uniform bool hasCeiling;
uniform bool hasSkylight;

// 纹理
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
// 方块与实体纹理图集, 只在 gbuffers 与 shadow 阶段有意义
uniform sampler2D gtexture;
