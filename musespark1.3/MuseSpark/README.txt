# 雾棱山晓原创 Iris 光影
# 目标版本 1.21.11
# 全部 GLSL 均为原创编写
# 安装方式
# 解压后把 MuseSpark 文件夹放入 .minecraft/shaderpacks
# 游戏内依次打开选项视频设置光影选择 MuseSpark
# 可调参数
# MIST_AMOUNT 山雾浓度
# PRISM_AMOUNT 棱镜色散与辉光强度
# SHADOW_SOFT 阴影柔化半径
# EXPOSURE 曝光
# CLOUD_COVER 云量
# 管线说明
# shadow 负责阴影深度与树叶镂空
# gbuffers 系列打包反照率光照法线与材质标记
# deferred 负责天空云星阴影水体反射焦散与雾海
# composite 负责棱镜色散辉光与暗角
# final 负责曝光色调映射与抖动抗色带
