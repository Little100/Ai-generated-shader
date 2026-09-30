# Asterweave

Asterweave 是一套为 Iris 设计的原创 Minecraft 光影。它把天空想象成会随世界时间缓慢编织的光幕，地表光照保持方块结构的清晰度，同时用低成本的辉光、薄雾、色散和颗粒把画面连接起来。

## 视觉方向

- 晴天会偏向清透的青蓝与温金色，黄昏会出现短暂的紫铜色过渡。
- 夜晚不会单纯变黑，而是保留冷蓝月光与很轻的星织光带。
- 地形光照加入了柔和的方向性，水面使用独立的波纹色调。
- 后处理使用多点辉光、边缘色散、雨天冷色雾和时间驱动的细微颗粒。
- 地形加入轻量 3x3 PCF 太阳阴影，阴影坐标由 Iris 的阴影矩阵驱动。

## 使用方式

将 `Asterweave` 文件夹放入 Minecraft 的 `shaderpacks` 文件夹，或使用同目录下的 `Asterweave-1.21.11-Iris.zip`。

目标环境是 Minecraft 1.21.11 与 Iris。光影不读取其他光影包的代码、资源或配置。

## 性能建议

- `shaders.properties` 中的 `shadowMapResolution` 与 `shadowDistance` 控制阴影贴图的清晰度和范围。
- 如果显卡压力较高，可以在 Iris 设置中降低渲染分辨率或关闭阴影。
- 画面效果主要集中在 `composite` 与 `composite1`，便于继续维护和扩展。
