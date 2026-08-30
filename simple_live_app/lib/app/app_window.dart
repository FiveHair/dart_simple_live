import 'package:flutter/widgets.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_manager_plus/window_manager_plus.dart' as wmp;

import 'app_platform.dart';

/// 桌面窗口管理适配层
///
/// - Windows / macOS / Linux：使用 window_manager
/// - 鸿蒙 PC：window_manager 无 ohos 实现，使用 window_manager_plus
///
/// 用法与 window_manager 的全局 [windowManager] 保持一致，
/// 通过 [AppWindow.xxx] 调用，内部按平台分发。
class AppWindow {
  AppWindow._();

  /// 鸿蒙（含鸿蒙 PC）使用 window_manager_plus
  static bool get _usePlus => AppPlatform.isOhos;

  static wmp.WindowManagerPlus get _plus => wmp.WindowManagerPlus.current;

  static Future<void> ensureInitialized() async {
    if (_usePlus) {
      await wmp.WindowManagerPlus.ensureInitialized(0);
    } else {
      await windowManager.ensureInitialized();
    }
  }

  static Future<void> waitUntilReadyToShow({
    Size? minimumSize,
    bool? center,
    String? title,
    required VoidCallback callback,
  }) async {
    if (_usePlus) {
      await _plus.waitUntilReadyToShow(
        wmp.WindowOptions(
          minimumSize: minimumSize,
          center: center,
          title: title,
        ),
        callback,
      );
    } else {
      await windowManager.waitUntilReadyToShow(
        WindowOptions(
          minimumSize: minimumSize,
          center: center,
          title: title,
        ),
        callback,
      );
    }
  }

  static Future<void> show() async =>
      _usePlus ? _plus.show() : windowManager.show();

  static Future<void> focus() async =>
      _usePlus ? _plus.focus() : windowManager.focus();

  static Future<bool> isFullScreen() async =>
      _usePlus ? _plus.isFullScreen() : windowManager.isFullScreen();

  static Future<void> setFullScreen(bool isFullScreen) async => _usePlus
      ? _plus.setFullScreen(isFullScreen)
      : windowManager.setFullScreen(isFullScreen);

  static Future<void> setTitleBarStyle(TitleBarStyle style) async {
    if (_usePlus) {
      await _plus.setTitleBarStyle(
        style == TitleBarStyle.hidden
            ? wmp.TitleBarStyle.hidden
            : wmp.TitleBarStyle.normal,
      );
    } else {
      await windowManager.setTitleBarStyle(style);
    }
  }

  static Future<Size> getSize() async =>
      _usePlus ? _plus.getSize() : windowManager.getSize();

  static Future<Offset> getPosition() async =>
      _usePlus ? _plus.getPosition() : windowManager.getPosition();

  static Future<void> setSize(Size size) async =>
      _usePlus ? _plus.setSize(size) : windowManager.setSize(size);

  static Future<void> setPosition(Offset position) async => _usePlus
      ? _plus.setPosition(position)
      : windowManager.setPosition(position);

  static Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async => _usePlus
      ? _plus.setAlwaysOnTop(isAlwaysOnTop)
      : windowManager.setAlwaysOnTop(isAlwaysOnTop);

  static Future<void> setTitle(String title) async =>
      _usePlus ? _plus.setTitle(title) : windowManager.setTitle(title);
}

/// DragToMoveArea 的跨平台包装（隐藏标题栏后拖动窗口）
class AppDragToMoveArea extends StatelessWidget {
  const AppDragToMoveArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppPlatform.isOhos) {
      return wmp.DragToMoveArea(child: child);
    }
    return DragToMoveArea(child: child);
  }
}
