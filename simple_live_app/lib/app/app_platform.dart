import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

/// 平台判定工具
///
/// 鸿蒙（OHOS）说明：
/// - CPF Flutter SDK 中 [Platform.operatingSystem] 返回 "ohos"，
///   这里使用字符串比较，保证在官方 Flutter SDK（Android/iOS/桌面端）下也能编译
/// - 鸿蒙手机/平板：功能对齐 Android 手机/平板（[isMobile]）
/// - 鸿蒙 PC（2in1 等桌面形态设备）：窗口行为对齐 Windows（[isDesktopForm]）
class AppPlatform {
  AppPlatform._();

  /// 是否为鸿蒙系统
  static bool get isOhos => Platform.operatingSystem == "ohos";

  /// 是否为移动端形态（手机/平板）：Android / iOS / 鸿蒙
  static bool get isMobile => Platform.isAndroid || Platform.isIOS || isOhos;

  /// 是否为移动端形态的设备（手机/平板机身）
  ///
  /// 区别于 [isMobile]：鸿蒙 PC 属于移动端系统但为桌面形态，
  /// 交互行为（全屏方式、手势等）应对齐 Windows
  static bool get isMobileForm => isMobile && !isOhosPC;

  /// 是否为传统桌面端：Windows / macOS / Linux
  static bool get isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  /// 是否为鸿蒙 PC（2in1 等桌面形态），需要在启动时调用 [init] 后才有效
  static bool isOhosPC = false;

  /// 是否为桌面形态：传统桌面端 + 鸿蒙 PC
  static bool get isDesktopForm => isDesktop || isOhosPC;

  /// 是否支持窗口管理（window_manager / window_manager_plus）
  static bool get supportWindowManager => isDesktopForm;

  /// 初始化设备形态检测（main 中最先调用）
  static Future<void> init() async {
    if (!isOhos) {
      return;
    }
    try {
      final info = await DeviceInfoPlugin().ohosDeviceInfo;
      // deviceType: phone / tablet / 2in1 / tv / wearable ...
      isOhosPC = info.deviceType == "2in1" || info.deviceType == "pc";
    } catch (_) {
      isOhosPC = false;
    }
  }
}
