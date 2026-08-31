import 'dart:async';

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

  /// 鸿蒙端窗口调用统一兜底。
  ///
  /// window_manager_plus 的 ohos 实现有两类缺陷：
  /// 1. setAlignment / setSize / setPosition / setAlwaysOnTop 等方法未实现，
  ///    落到 default 分支返回 notImplemented，Dart 侧抛 MissingPluginException；
  /// 2. setMinimumSize / setTitle / focus 等方法已实现但从不回包，
  ///    Dart 侧 await 会永久挂起。
  ///
  /// 这些方法一旦出现在启动链路（main 的 initWindow）中，runApp 之前就会
  /// 抛异常或卡死，表现为鸿蒙 PC 打开即白屏（手机端不走窗口链路，不受影响）。
  /// 因此鸿蒙端所有窗口调用统一 catch + 超时，窗口问题不允许阻塞应用。
  static Future<T?> _run<T>(Future<T> Function() body) async {
    if (!_usePlus) {
      return body();
    }
    try {
      return await body().timeout(const Duration(seconds: 2));
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<void> ensureInitialized() async {
    if (_usePlus) {
      await _run(() => wmp.WindowManagerPlus.ensureInitialized(0));
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
      // ohos 端 center / minimumSize / title 分别对应未实现或不回包的方法
      // （见 [_run] 注释），不能传入，否则启动即白屏；只保留回调
      await _run(
        () => _plus.waitUntilReadyToShow(const wmp.WindowOptions(), callback),
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

  static Future<void> show() async {
    if (_usePlus) {
      await _run(_plus.show);
    } else {
      await windowManager.show();
    }
  }

  static Future<void> focus() async {
    if (_usePlus) {
      await _run(_plus.focus);
    } else {
      await windowManager.focus();
    }
  }

  static Future<bool> isFullScreen() async {
    if (_usePlus) {
      return await _run(_plus.isFullScreen) ?? false;
    }
    return windowManager.isFullScreen();
  }

  static Future<void> setFullScreen(bool isFullScreen) async {
    if (_usePlus) {
      await _run(() => _plus.setFullScreen(isFullScreen));
    } else {
      await windowManager.setFullScreen(isFullScreen);
    }
  }

  static Future<void> setTitleBarStyle(TitleBarStyle style) async {
    if (_usePlus) {
      await _run(
        () => _plus.setTitleBarStyle(
          style == TitleBarStyle.hidden
              ? wmp.TitleBarStyle.hidden
              : wmp.TitleBarStyle.normal,
        ),
      );
    } else {
      await windowManager.setTitleBarStyle(style);
    }
  }

  static Future<Size> getSize() async {
    if (_usePlus) {
      return await _run(_plus.getSize) ?? Size.zero;
    }
    return windowManager.getSize();
  }

  static Future<Offset> getPosition() async {
    if (_usePlus) {
      return await _run(_plus.getPosition) ?? Offset.zero;
    }
    return windowManager.getPosition();
  }

  static Future<void> setSize(Size size) async {
    if (_usePlus) {
      await _run(() => _plus.setSize(size));
    } else {
      await windowManager.setSize(size);
    }
  }

  static Future<void> setPosition(Offset position) async {
    if (_usePlus) {
      await _run(() => _plus.setPosition(position));
    } else {
      await windowManager.setPosition(position);
    }
  }

  static Future<void> setAlwaysOnTop(bool isAlwaysOnTop) async {
    if (_usePlus) {
      await _run(() => _plus.setAlwaysOnTop(isAlwaysOnTop));
    } else {
      await windowManager.setAlwaysOnTop(isAlwaysOnTop);
    }
  }

  static Future<void> setTitle(String title) async {
    if (_usePlus) {
      await _run(() => _plus.setTitle(title));
    } else {
      await windowManager.setTitle(title);
    }
  }
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
