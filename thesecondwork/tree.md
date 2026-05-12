E:.   # 项目根目录：avplayer-play-formatted-audio-cpp
|   .clang-tidy   # C++ 代码静态检查配置
|   .clangd   # C++ 语言服务器配置
|   .gitignore   # Git 忽略文件列表
|   build-profile.json5   # 项目级构建配置（签名、产品类型等）
|   code-linter.json5   # 代码规范检查配置
|   hvigorfile.ts   # 项目级构建脚本入口
|   local.properties   # 本地 SDK 路径（自动生成）
|   OAT.xml   # 开源审核配置
|   oh-package-lock.json5   # 依赖版本锁定文件
|   oh-package.json5   # 项目依赖声明（如 @ohos/hypium）
|   ragConfig.json   # CodeGenie AI 知识库配置
|   README.md   # 项目说明文档
|   tree.txt   # 你生成的目录树文件（可忽略）
|   
+---.hvigor   # hvigor 构建工具缓存目录（自动生成，可忽略）
|   +---cache   # 构建缓存文件
|   +---dependencyMap   # 依赖映射
|   +---outputs   # 构建输出日志
|   \---report   # 构建报告（JSON）
|   
+---.idea   # IDE 项目配置目录
|   |   .gitignore   # IDE 本地忽略配置
|   |   modules.xml   # 模块定义
|   |   vcs.xml   # 版本控制配置（Git）
|   |   workspace.xml   # 工作区状态
|   |   
|   +---.deveco   # DevEco 特定配置
|   |   |   project.cache.json   # 项目缓存
|   |   +---cxx   # C++ 相关配置
|   |   \---module   # 模块缓存
|   \---modules   # 模块定义文件
|           avplayer-play-formatted-audio-cpp.iml   # 根模块描述
|           entry.iml   # entry 模块描述
|   
+---.lancedb   # LanceDB 向量数据库（CodeGenie 知识库缓存）
|   \---knowledge_base.lance
|       +---_transactions
|       \---_versions
|   
+---AppScope   # 全局应用配置目录
|   |   app.json5   # 应用全局配置（包名、版本、图标等）
|   \---resources
|       \---base
|           +---element
|           |       string.json   # 应用名称等字符串资源
|           \---media
|                   background.png   # 应用背景图
|                   foreground.png   # 应用前景图
|                   layered_image.json   # 分层图标描述
|   
+---entry   # 主模块（核心代码）
|   |   build-profile.json5   # 模块级构建配置（已添加 abiFilters）
|   |   hvigorfile.ts   # 模块级构建脚本
|   |   obfuscation-rules.txt   # 代码混淆规则
|   |   oh-package-lock.json5   # 模块依赖锁定
|   |   oh-package.json5   # 模块依赖声明
|   |   
|   +---.cxx   # C++ 构建中间目录（CMake 输出，自动生成）
|   |   \---default
|   |       \---default
|   |           \---debug
|   |               +---arm64-v8a   # ARM 架构构建产物
|   |               |   |   .ninja_deps   # Ninja 依赖
|   |               |   |   .ninja_log   # Ninja 日志
|   |               |   |   additional_project_files.txt
|   |               |   |   build.ninja   # Ninja 构建脚本
|   |               |   |   build_file_index.txt
|   |               |   |   CMakeCache.txt   # CMake 缓存
|   |               |   |   cmake_install.cmake
|   |               |   |   compile_commands.json   # 编译命令数据库
|   |               |   |   configure_fingerprint.json
|   |               |   |   hvigor_native_config.json
|   |               |   |   metadata_generation_command.txt
|   |               |   |   native_work_dir.txt
|   |               |   |   output.log   # 编译输出日志
|   |               |   |   
|   |               |   +---.cmake   # CMake API 缓存
|   |               |   \---CMakeFiles   # CMake 内部文件
|   |               +---hvigor   # hvigor 与 CMake 集成文件
|   |               \---x86_64   # x86_64 架构构建产物（模拟器用）
|   |   
|   +---build   # 模块构建输出目录
|   |   +---config
|   |   \---default
|   |       +---cache   # ArkTS 编译缓存
|   |       +---generated   # 自动生成的代码（如 BuildProfile.ets）
|   |       +---intermediates   # 中间文件（.so, .hap 等）
|   |       \---outputs   # 最终产物：entry-default-unsigned.hap
|   |   
|   +---oh_modules   # 模块级依赖（libentry.so 的 TypeScript 声明）
|   |   \---libentry.so
|   |           Index.d.ts
|   |           oh-package.json5
|   |   
|   \---src   # 源代码目录
|       \---main
|           |   module.json5   # 模块清单（Ability、权限、页面路由等）
|           |   
|           +---cpp   # C++ 原生代码
|           |   |   avplayer_playing_ndk.cpp   # JNI 接口，供 ArkTS 调用播放控制
|           |   |   CMakeLists.txt   # CMake 构建脚本，生成 libentry.so
|           |   |   
|           |   +---player
|           |   |       avplayer_playing.cpp   # 核心播放引擎（解码、播放、倍速、音量）
|           |   |       avplayer_playing.h   # 头文件
|           |   |   
|           |   \---types
|           |       \---libentry
|           |               Index.d.ts   # 原生模块的 TypeScript 声明
|           |               oh-package.json5
|           |   
|           +---ets   # ArkTS 源代码
|           |   +---common
|           |   |   +---constants
|           |   |   |       BreakpointConstants.ets   # 响应式布局断点常量
|           |   |   |       ContentConstants.ets   # 歌单数据常量
|           |   |   |       LyricConst.ets   # 歌词解析常量
|           |   |   |       PlayerConstants.ets   # 播放器状态常量
|           |   |   |       StyleConstants.ets   # 样式常量（颜色、间距）
|           |   |   |       
|           |   |   \---utils
|           |   |       |   BackgroundUtil.ets   # 后台播放管理
|           |   |       |   BreakpointSystem.ets   # 响应式布局工具
|           |   |       |   ColorConversion.ets   # 颜色转换
|           |   |       |   Logger.ets   # 日志输出
|           |   |       |   LrcUtils.ets   # 歌词文件解析（.lrc）
|           |   |       |   PreferencesUtil.ets   # 本地数据存储
|           |   |       |   ResourceConversion.ets   # 资源转换（如时长格式化）
|           |   |       |   
|           |   |       \---mediautils
|           |   |               AVSessionController.ets   # 系统媒体会话控制
|           |   |               MediaControlCenter.ets   # 媒体控制中心逻辑
|           |   |               MediaControlCenterCallbackAction.ets
|           |   |               MediaControlCenterHandle.ets
|           |   |               MediaTools.ets   # 媒体工具类
|           |   |               
|           |   +---component
|           |   |       CustomButton.ets   # 自定义按钮组件
|           |   |       
|           |   +---entryability
|           |   |       EntryAbility.ets   # 应用生命周期管理（onCreate等）
|           |   |       InsightIntentExecutorImpl.ets   # 意图框架实现（小艺语音控制）
|           |   |       
|           |   +---entrybackupability
|           |   |       EntryBackupAbility.ets   # 数据备份恢复支持
|           |   |       
|           |   +---model
|           |   |       SongListData.ets   # 歌单数据模型（歌曲信息结构）
|           |   |       
|           |   +---pages
|           |   |       Index.ets   # 主页面（歌单列表、播放控制、歌词显示）
|           |   |       
|           |   +---view
|           |   |       ControlAreaComponent.ets   # 播放控制栏（播放/暂停、上一曲/下一曲）
|           |   |       LrcView.ets   # 歌词滚动视图
|           |   |       LyricsComponent.ets   # 歌词组件（解析与显示）
|           |   |       MusicInfoComponent.ets   # 歌曲信息展示（封面、标题、歌手）
|           |   |       PlayerInfoComponent.ets   # 播放器详情（进度条、时间）
|           |   |       
|           |   \---viewmodel
|           |           LrcEntry.ets   # 歌词条目数据模型
|           |           SongData.ets   # 歌曲数据模型
|           |           SongDataSource.ets   # 歌单数据源（列表适配）
|           |           SongItemBuilder.ets   # 歌单项构建器
|           |           
|           \---resources   # 资源文件
|               +---base
|               |   +---element
|               |   |       color.json   # 颜色定义
|               |   |       float.json   # 浮点数值
|               |   |       string.json   # 字符串资源
|               |   |       
|               |   +---media   # 图片资源（图标、专辑封面等）
|               |   |       background.png
|               |   |       foreground.png
|               |   |       heart.svg
|               |   |       ... (约60+个图标文件)
|               |   |       
|               |   \---profile
|               |           backup_config.json   # 备份配置
|               |           insight_intent.json   # 语音意图声明
|               |           main_pages.json   # 页面路由配置
|               |           
|               +---dark   # 深色主题资源
|               |   \---element
|               |           color.json   # 深色模式颜色
|               |           
|               +---en_US   # 英文本地化
|               |   \---element
|               |           string.json
|               |           
|               +---rawfile   # 原始文件（音频、歌词）
|               |   |   boisterous.pcm
|               |   |   boisterous.wav
|               |   |   Delacey - Dream It Possible.flac   # 示例音频文件
|               |   |   Delacey - Dream It Possible.pcm
|               |   |   power.pcm
|               |   |   power.wav
|               |   |   world.pcm
|               |   |   world.wav
|               |   |   
|               |   \---lrcfiles
|               |           DreamItPossible.lrc   # 歌词文件
|               |           
|               \---zh_CN   # 中文本地化
|                   \---element
|                           string.json
|   
+---hvigor   # 全局 hvigor 配置
|       hvigor-config.json5   # hvigor 构建工具配置
|       
+---oh_modules   # 项目级依赖（npm 包）
|   +---.ohpm   # ohpm 包管理器缓存
|   |   |   lock.json5
|   |   +---@ohos+hamock@1.0.0   # 模拟测试框架
|   |   \---@ohos+hypium@1.0.24   # 单元测试框架
|   \---@ohos   # 依赖副本
|       +---hamock
|       \---hypium
|           
\---screenshots   # 运行截图（供文档使用）
    \---device
            index.png   # 主界面截图
            songList.png   # 歌单界面截图
            speed.png   # 倍速调节截图
            volume.png   # 音量调节截图