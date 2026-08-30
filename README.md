> ### ⚠ 本仓库为社区 Fork，新增 HarmonyOS（鸿蒙）平台支持，基于上游 `dev` 分支维护
> ### 鸿蒙/各平台安装包可在 [Actions](../../actions) 产物或 [Releases](../../releases) 中获取



<p align="center">
    <img width="128" src="/assets/logo.png" alt="Simple Live logo">
</p>
<h2 align="center">Simple Live</h2>

<p align="center">
简简单单的看直播
</p>

![浅色模式](/assets/screenshot_light.jpg)

![深色模式](/assets/screenshot_dark.jpg)

## 支持直播平台：

- 虎牙直播

- 斗鱼直播

- 哔哩哔哩直播

- 抖音直播

## APP支持平台

- [x] Android
- [x] iOS
- [x] Windows `BETA`
- [x] MacOS `BETA`
- [x] Linux `BETA`
- [x] Android TV `BETA`
- [x] HarmonyOS（手机/平板/PC，`ohos-support` 分支）

## 鸿蒙（HarmonyOS）说明

- 手机/平板功能对齐 Android 端，PC（2in1 形态）窗口行为对齐 Windows 端（含桌面小窗、双击全屏等）
- 已适配：原生全屏/智慧多窗、系统播控中心（AVSession）、手势亮度/音量、后台播放声明、
  折叠屏外屏与挖孔屏、文件导出、扫码、WebView 登录等
- 未适配：系统级画中画小窗（需 media_kit 渲染管线改造，见 `simple_live_app/README_OHOS.md`）
- CI 产出的 HAP 为未签名包，可通过 [小白调试助手](https://github.com/likuai2010/auto-installer)
  等方式安装，或用 DevEco Studio 自行签名
- 详细适配文档：[simple_live_app/README_OHOS.md](simple_live_app/README_OHOS.md)

## 获取安装包

推送到 `ohos-support` 分支会自动构建鸿蒙包（Actions → Build HarmonyOS）；
打 `v*` 标签或手动触发 **Release All Platforms** 会构建全平台产物
（Android / Windows / Linux / macOS / HarmonyOS，iOS 因需要签名证书未包含）。

## 项目结构

- `simple_live_core` 项目核心库，实现获取各个网站的信息及弹幕。
- `simple_live_console` 基于simple_live_core的控制台程序。
- `simple_live_app` 基于核心库实现的Flutter APP客户端。
- `simple_live_tv_app` 基于核心库实现的Flutter Android TV客户端。

## 环境

Flutter（FVM）: `3.47.1`

## 参考及引用

[AllLive](https://github.com/xiaoyaocz/AllLive) `本项目的C#版，有兴趣可以看看`

### 鸿蒙适配致谢

- [xiaoyaocz/dart_simple_live](https://github.com/xiaoyaocz/dart_simple_live) `原项目作者`
- [ErBWs/Kazumi](https://github.com/ErBWs/Kazumi) `鸿蒙适配的重要参考（原生全屏/智慧多窗/模块配置等），以及其 CI 方案`
- [CPF-Flutter](https://gitcode.com/CPF-Flutter) `鸿蒙 Flutter SDK（flutter_flutter oh-3.41.9）与全套插件适配生态`
- [OpenHarmony SIG](https://gitcode.com/openharmony-sig) `鸿蒙三方库适配社区`

[dart_tars_protocol](https://github.com/xiaoyaocz/dart_tars_protocol.git)

[wbt5/real-url](https://github.com/wbt5/real-url)

[lovelyyoshino/Bilibili-Live-API](https://github.com/lovelyyoshino/Bilibili-Live-API/blob/master/API.WebSocket.md)

[IsoaSFlus/danmaku](https://github.com/IsoaSFlus/danmaku)

[BacooTang/huya-danmu](https://github.com/BacooTang/huya-danmu)

[TarsCloud/Tars](https://github.com/TarsCloud/Tars)

[YunzhiYike/douyin-live](https://github.com/YunzhiYike/douyin-live)

[5ime/Tiktok_Signature](https://github.com/5ime/Tiktok_Signature)

## 声明

本项目的所有功能都是基于互联网上公开的资料开发，无任何破解、逆向工程等行为。

本项目仅用于学习交流编程技术，严禁将本项目用于商业目的。如有任何商业行为，均与本项目无关。

如果本项目存在侵犯您的合法权益的情况，请及时与开发者联系，开发者将会及时删除有关内容。

## Star History

<a href="https://www.star-history.com/#xiaoyaocz/dart_simple_live&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=xiaoyaocz/dart_simple_live&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=xiaoyaocz/dart_simple_live&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=xiaoyaocz/dart_simple_live&type=Date" />
 </picture>
</a>
