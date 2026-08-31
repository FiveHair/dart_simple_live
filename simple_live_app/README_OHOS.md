# Simple Live 鸿蒙（HarmonyOS/OHOS）适配说明

本项目在保留 Android / iOS / Windows / macOS / Linux 全部原有目标的基础上，新增了鸿蒙平台支持：

- **鸿蒙手机 / 平板**：功能对齐 Android 手机 / 平板（全屏手势、音量手势、横竖屏、相册保存、扫码、WebView 登录等）
- **鸿蒙 PC（2in1 形态设备）**：窗口行为对齐 Windows（小窗悬浮窗、双击全屏、窗口置顶等，通过 `window_manager_plus` 实现）

## 一、环境要求

| 组件 | 版本 | 说明 |
| ---- | ---- | ---- |
| Flutter (ohos) | `oh-3.41.9-release` | https://gitcode.com/CPF-Flutter/flutter_flutter |
| DevEco Studio | 5.1+（本仓库在 API 26 SDK 上验证） | 含 HarmonyOS SDK、ohpm、hvigor、node |
| 环境变量 | `DEVECO_SDK_HOME` | 指向 DevEco 的 sdk 目录 |
| 环境变量 | `TOOL_HOME`（可选） | 指向 DevEco 安装目录，用于 hvigorw.bat 定位工具链 |
| PATH | DevEco 的 `tools/ohpm/bin`、`tools/hvigor/bin`、`tools/node/bin` | 构建期使用 |
| 环境变量 | `PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn` | 国内镜像 |
| 环境变量 | `git config --global lfs.fetchexclude "example/**"`（必须） | permission_handler 仓库 example 目录有服务端缺失的 LFS 文件；其余 LFS 大文件（libmpv 等）必须正常下载，否则 HAP 内是指针文件、安装后白屏 |

```bash
git clone -b oh-3.41.9-release https://gitcode.com/CPF-Flutter/flutter_flutter.git flutter_ohos
export PATH="$PWD/flutter_ohos/bin:$PATH"
flutter doctor   # 引导下载 Dart SDK 与 ohos engine 产物
```

## 二、构建

```bash
cd simple_live_app
flutter pub get
flutter build hap --debug   # 产物: ohos/entry/build/default/outputs/default/entry-default-unsigned.hap
```

- 安装到真机需要签名：用 DevEco Studio 打开 `simple_live_app/ohos`，在
  File → Project Structure → Signing Configs 勾选 Automatically generate signature。
- 运行调试：`flutter run`（连接 hdc 设备）。

## 三、适配内容

### 1. pubspec：ohos 适配版插件（`dependency_overrides`）

所有覆盖均为「上游官方代码 + ohos 平台扩展」的适配版，版本与主依赖约束一致，
其他平台使用的仍是对应上游版本的实现，行为不变：

| 依赖 | 来源 | ref |
| ---- | ---- | ---- |
| media_kit / media_kit_video / media_kit_libs_video | CPF-Flutter/fluttertpc_flutter_media_kit | `1.2.6-ohos-1.0.0` |
| media_kit_libs_windows_video | 同上（libs/windows 子目录，1.0.12 仅有适配版） | 同上 |
| path_provider(+_ohos) / url_launcher(+_ohos) | CPF-Flutter/flutter_packages | `br_path_provider-v2.1.5_ohos` / `br_url_launcher-v6.3.2_ohos` |
| device_info_plus / package_info_plus / connectivity_plus / network_info_plus / share_plus | CPF-Flutter/flutter_plus_plugins | 各自版本匹配分支（12.3.0 / 9.0.0 / 7.0.0 / 7.0.0 / 12.0.1） |
| permission_handler | CPF-Flutter/flutter_permission_handler | `br_v12.0.1_ohos` |
| wakelock_plus | CPF-Flutter/fluttertpc_wakelock_plus | `br_v1.4.0_ohos` |
| volume_controller / image_gallery_saver_plus / qr_code_scanner_plus | 各 fluttertpc 仓库 | master |
| flutter_inappwebview | CPF-Flutter/flutter_inappwebview | `br_v6.1.5_ohos` |
| file_picker | 以 `file_picker_ohos`（上游 10.3.8 全平台 fork + podspec 修复）替换 | [`ohos-podspec-fix`](https://github.com/FiveHair/fluttertpc_file_picker/tree/ohos-podspec-fix) |
| window_manager_plus（新增，鸿蒙 PC 窗口管理） | CPF-Flutter/fluttertpc_window_manager_plus | master |
| dart_quickjs | 本仓库 `third_party/dart_quickjs`（见下） | — |

`flutter packages` 系列仓库的 ref 选择依据其 README 中的「TAG 版本对应表」。

### 2. 平台判定（`lib/app/app_platform.dart`）

新增 `AppPlatform` 工具类统一平台判定（`Platform.operatingSystem == "ohos"`，
保证在官方 Flutter SDK 下也能编译）：

- `isOhos`：是否鸿蒙系统
- `isMobile`：Android / iOS / 鸿蒙（能力维度：相册、WebView、扫码等）
- `isMobileForm`：手机/平板**形态**（鸿蒙 PC 不算，交互走桌面路径）
- `isDesktop`：Windows / macOS / Linux
- `isDesktopForm`：桌面**形态**（传统桌面 + 鸿蒙 PC，窗口/滚动条/悬浮窗等）
- `AppPlatform.init()`：启动时通过 `device_info_plus` 的 `deviceType`（`2in1`/`pc`）识别鸿蒙 PC

全仓库约 70 处 `Platform.isXxx` 已按「能力」与「形态」两个维度改写。

### 3. 窗口管理适配（`lib/app/app_window.dart`）

`AppWindow` 封装双通道：传统桌面用 `window_manager`，鸿蒙用 `window_manager_plus`
（API 镜像 window_manager：setFullScreen / setSize / setAlwaysOnTop / setTitleBarStyle 等），
并提供 `AppDragToMoveArea` 替代 `DragToMoveArea`。

### 4. 框架 API 兼容

ohos SDK（Flutter 3.41.9）低于仓库锁定的官方版本（3.47.1），已将
`ReorderableListView.onReorderItem`（3.46+ 新 API）降级为两版兼容的 `onReorder`
（含索引修正，行为不变）。

### 5. dart_quickjs（`third_party/dart_quickjs`）

`simple_live_core` 依赖的 dart_quickjs 通过 native assets 编译 quickjs-ng。
其构建钩子不认识鸿蒙工具链，已在本仓库副本中补充：检测到 HarmonyOS SDK 的 clang
（`input.config.code.cCompiler`）时追加 `--target=<arch>-linux-ohos --sysroot=<sdk>/native/sysroot`。
上游修复后可移除此覆盖。

### 5.1 flutter_tools 双补丁（`tool/patch_flutter_tools_ohos.py`）

**补丁 1：native assets manifest（全平台、全构建模式）**

flutter-ohos 的 `flutter_tools` 在 ohos 构建时不会把
`NativeAssetsManifest.json` 打进 flutter_assets（android/macos 均会），导致
运行时报 `No asset with id ... found. No available native assets.`
（如斗鱼房间加载时 dart_quickjs 找不到 `JS_NewRuntime`）。

**补丁 2：Windows 下 ohpm spawn（仅 Windows 构建机生效）**

flutter_tools 的 `ohpmInstall` 直接 spawn 裸 `['ohpm', 'install', '--all']`，
Windows 上 ohpm 只有 `ohpm.bat`（CreateProcess 不认无扩展名脚本），必报
"系统找不到指定的文件"。补丁改为优先调用项目内修复版垫片
`ohos/build-tools/ohpm/bin/ohpm.bat`（见下文 6），不存在时回退
`cmd /c ohpm.bat`。

修复脚本对本地 SDK（默认 `D:\flutter_flutter`）执行；**升级/切换 flutter-ohos
SDK 分支后需要重新执行一次**：

```bash
python tool/patch_flutter_tools_ohos.py          # 或显式传入 SDK 路径
```

脚本幂等，会自动清理工具快照缓存触发重建。

**SDK 克隆注意事项**：克隆 flutter_flutter 时不要用 `--depth 1` ——
flutter_tools 靠 git tag 解析 SDK 版本，浅克隆拿不到 tag 时版本会变成
`0.0.0-unknown`，`pub get` 直接版本求解失败（CI 曾因此全平台失败）。


### 6. Windows 构建垫片（`ohos/hvigorw.bat` + `ohos/tool-shims/`）

DevEco 的 `ohpm.bat` 存在批处理无限递归 bug（`%VAR%` 在代码块内的过早展开），
在 flutter（Dart 进程）派生的 cmd 环境下触发 "BATCH RECURSION exceeds STACK limits"。
修复方式：

- `ohos/hvigorw.bat`：flutter 工具链在 Windows 上的入口，将 DevEco 的 hvigor
  目录镜像到 `ohos/build-tools/hvigor`（gitignore，一次性 robocopy），并把我们
  修复的 ohpm 垫片放到 `ohos/build-tools/ohpm/bin/ohpm.bat` —— hvigorw.js 会以
  `<hvigor>/../../ohpm/bin/ohpm.bat` 解析 ohpm，正好命中垫片；
- `ohos/tool-shims/ohpm.bat`：直接委托 `node pm-cli.js`，绕过有 bug 的参数剥离逻辑；
- flutter_tools 自身 spawn 裸 `ohpm` 的问题由 5.1 的补丁 2 处理。

**Windows 本地构建还要求 SDK、pub 缓存与项目在同一盘符**：flutter_tools 用
`path.relative` 计算插件模块的 `srcPath`，跨盘符（如 pub 缓存在 `C:`、项目在
`D:`）会退化成绝对路径，hvigor 报
`AdaptorError 00303231 The srcPath is not a relative path`。设置
`PUB_CACHE=D:\pub-cache`（与项目同盘）即可。克隆 flutter_flutter 时也不要用
`--depth 1`（见 5.1 末尾）。

### 7. 未适配 / 已知差异

- **window_manager_plus ohos 实现能力缺口**（`lib/app/app_window.dart` 已统一兜底）：
  - setAlignment / setSize / setPosition / setAlwaysOnTop / setTitle 等未实现，
    调用抛 `MissingPluginException`；setMinimumSize / setTitle / focus 等
    已实现但**从不回包**，`await` 会永久挂起；
  - 这些方法若出现在启动链路（`main` 的 `initWindow`）中，`runApp` 之前就会
    抛异常或卡死，**表现为鸿蒙 PC 打开即白屏**（手机端不走窗口链路，不受影响）。
    `AppWindow` 已对鸿蒙端全部窗口调用做 catch + 2s 超时兜底，且启动时不再传
    center / minimumSize / title；
  - 由此在鸿蒙 PC 上**降级为 no-op** 的能力：悬浮小窗改窗口尺寸/置顶、
    自定义窗口标题、窗口最小尺寸限制（全屏切换 `setFullScreen`、窗口拖动
    `DragToMoveArea` 正常）。
- **CI 产物 ABI**：`flutter build hap` 默认仅打 `ohos-arm64`。鸿蒙 PC 真机
  （Kirin，arm64）可用；DevEco 的 **PC 模拟器为 x86_64**，安装 arm64 包无法
  运行（如需模拟器包需 `--target-platform ohos-x64`，CPF 引擎 x64 release
  产物可用性待验证）。
- `floating`（Android PiP 小窗）无鸿蒙适配：floating 包仅支持 Android，CPF 生态也
  暂无 PiP 类适配插件，鸿蒙手机端的"小窗播放"入口暂隐藏。如需实现需自研
  `@ohos.PiPWindow` 的 ohos 插件并对接 media_kit 的渲染管线（详见 issue 记录）。
- `auto_orientation_v2` 仅 Android 生效；鸿蒙横竖屏切换走 `SystemChrome`。
- `flutter_inappwebview` 在 Windows 上的默认实现缺失告警为上游已知状态，
  应用仅在移动端形态使用 WebView，不影响其他平台构建。
- 鸿蒙端截图保存到相册走 `image_gallery_saver_plus` + `permission_handler` ohos 适配版。

### 8. 真机反馈修复记录

- 播放页返回后声音残留：`onClose` 中系统状态重置（SystemChrome/方向/亮度/常亮）
  在部分平台抛异常会中断 `player.dispose()`，已改为逐项容错且播放器优先释放。
- 手势调节音量/亮度无提示：手势 Tip 与亮度手势的平台判断已加入 ohos
  （screen_brightness 官方已内置 ohos 实现）。

### 9. 鸿蒙特性适配（参考 Kazumi 的做法）

参考 [ErBWs/Kazumi](https://github.com/ErBWs/Kazumi) 的鸿蒙适配：

- **原生全屏**（`ohos/entry/src/main/ets/entryability/MethodCall.ets` +
  `lib/app/ohos_native.dart`，通道 `com.simplelive.app/intent`）：
  鸿蒙手机/平板的全屏不再走 SystemChrome（无法完整隐藏导航小白条），改为原生实现：
  隐藏状态栏与导航小白条、横屏自动旋转（竖屏直播间不锁横）、支持智慧多窗
  （横屏分屏）、窗口最大化；退出时恢复系统栏、手机恢复竖屏。
- **module.json5**：`avoid_cutout`（避开挖孔屏）、`orientation:
  auto_rotation_unspecified` + `preferMultiWindowOrientation: landscape_auto`
  （自由旋转/横屏多窗）、`backgroundModes: audioPlayback` +
  `ohos.permission.KEEP_BACKGROUND_RUNNING`（后台音频播放基础声明）。
- **API 版本**：`compatibleSdkVersion`/`targetSdkVersion` 对齐 Kazumi 的
  `6.0.0(20)`（即最低要求 HarmonyOS 6.0；`enableLandscapeMultiWindow` 等接口
  需要 API 20+）。
- 未搬移的 Kazumi 特性：外部播放器（m3u8 mime 唤起）、应用内自更新安装器——
  simple_live 暂无对应功能入口。

### 10. 真机反馈第二轮（导出/播控中心/外屏适配）

- **导出文件**：file_picker_ohos 的 `saveFile` 在"仅传文件名+bytes"场景下无法
  预填文件名（其实现依赖先选文件才有 `savaFilePath`），导出配置/保存日志在鸿蒙
  上改走 `MethodCall.ets` 的原生 `saveFile`（DocumentViewPicker + 文件写入）。
- **播控中心（AVSession）**：`MethodCall.ets` 通过 `@kit.AVSessionKit` 创建
  AVSession，上报直播间标题/主播名与播放状态；系统播控的播放/暂停/停止命令
  回传控制播放器。接线在 `LiveRoomController.initOhosAVSession`。
- **Pura X 外屏等异形屏**：全屏（隐藏系统栏后 MediaQuery padding 归零）时贴边
  控件可能被物理圆角/挖孔裁切，`buildFullControls` 的安全边距增加了最小值下限
  （上 6 / 下 8 / 左右 8）。
- **小窗（PiP）**：仍未实现。floating 无鸿蒙适配；系统级 PiPWindow 需要将
  media_kit 的视频渲染切换到 PiP 窗口的 XComponent surface（涉及 media_kit
  ohos 深度改造），建议作为独立需求排期。



## 四、其他平台回归

`flutter analyze`（ohos 3.41.9 SDK 下全量）零问题；ohos 以外的平台编译不受影响：
代码层仅使用两版框架共有的 API，插件覆盖在非 ohos 平台即为上游实现。
Windows/Android 原生构建需要对应工具链（Visual Studio / Android SDK），本机未安装，
建议在 CI 或装有工具链的环境执行 `flutter build windows` / `flutter build apk` 做最终确认。
