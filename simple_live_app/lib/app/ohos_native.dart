import 'package:flutter/services.dart';

import 'app_platform.dart';
import 'log.dart';

/// 鸿蒙原生能力通道
///
/// 对应 ohos 工程的 MethodCall.ets（参考 Kazumi 的适配实现）：
/// - 全屏：隐藏状态栏与导航小白条、横屏自动旋转、支持智慧多窗、窗口最大化。
///   SystemChrome 的沉浸模式在鸿蒙上无法完整隐藏导航小白条，故走原生实现
/// - 保存文件：系统保存对话框导出（file_picker_ohos 的 save 存在无法
///   预填文件名的问题，这里用原生补齐）
/// - 播控中心：AVSession 元数据/播放状态上报与系统播控命令回调
class OhosNative {
  OhosNative._();

  static const MethodChannel _channel =
      MethodChannel('com.simplelive.app/intent');

  /// 播控中心命令回调（play / pause / stop）
  static void Function(String command)? onAVSessionCommand;

  /// 初始化原生通道（main 中调用一次）
  static void init() {
    if (!AppPlatform.isOhos) {
      return;
    }
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'avSessionCommand') {
        final command = call.arguments as String?;
        if (command != null && command.isNotEmpty) {
          onAVSessionCommand?.call(command);
        }
      }
      return null;
    });
  }

  /// 进入原生全屏
  ///
  /// [lockLandscape] 为 true 时锁定横屏自动旋转（横屏直播间），否则自由旋转
  static Future<void> enterFullScreen({bool lockLandscape = true}) async {
    if (!AppPlatform.isOhos) {
      return;
    }
    try {
      await _channel.invokeMethod(
        'enterFullscreen',
        <String, bool>{'needSet': lockLandscape},
      );
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 退出原生全屏（恢复系统栏、手机恢复竖屏、恢复窗口）
  static Future<void> exitFullScreen() async {
    if (!AppPlatform.isOhos) {
      return;
    }
    try {
      await _channel.invokeMethod('exitFullscreen');
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 拉起系统保存对话框导出文件内容
  ///
  /// 返回保存的文件路径；用户取消时返回 null
  static Future<String?> saveFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (!AppPlatform.isOhos) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String>(
        'saveFile',
        <String, dynamic>{'fileName': fileName, 'bytes': bytes},
      );
    } catch (e) {
      Log.logPrint(e);
      return null;
    }
  }

  /// 创建并激活播控中心会话
  static Future<void> avSessionCreate() async {
    if (!AppPlatform.isOhos) {
      return;
    }
    try {
      await _channel.invokeMethod('avSessionCreate');
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 更新播控中心的元数据与播放状态
  static Future<void> avSessionUpdate({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    if (!AppPlatform.isOhos) {
      return;
    }
    try {
      await _channel.invokeMethod('avSessionUpdate', <String, dynamic>{
        'title': title,
        'artist': artist,
        'isPlaying': isPlaying,
      });
    } catch (e) {
      Log.logPrint(e);
    }
  }

  /// 销毁播控中心会话
  static Future<void> avSessionDestroy() async {
    if (!AppPlatform.isOhos) {
      return;
    }
    try {
      await _channel.invokeMethod('avSessionDestroy');
    } catch (e) {
      Log.logPrint(e);
    }
  }
}
