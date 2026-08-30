import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodChannel,
  MethodResult
} from "@ohos/flutter_ohos";
import { common } from "@kit.AbilityKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { window, display } from "@kit.ArkUI";
import { deviceInfo } from '@kit.BasicServicesKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { picker } from '@kit.CoreFileKit';
import { avSession as AVSession } from '@kit.AVSessionKit';

/**
 * 鸿蒙原生能力插件（参考 Kazumi 的适配实现）
 *
 * - enterFullscreen / exitFullscreen：真正的鸿蒙全屏
 *   隐藏状态栏与导航条小白条、横屏自动旋转、支持智慧多窗、窗口最大化，
 *   SystemChrome 的沉浸模式在鸿蒙上无法完整隐藏小白条，故走原生实现
 * - saveFile：系统保存对话框导出文件（file_picker_ohos 的 save 在
 *   “仅传文件名+bytes”场景下无法预填文件名，这里补齐实现）
 * - avSession 系列：接入系统播控中心（通知面板/控制中心的媒体控制卡片）
 */
export default class MethodCallPlugin implements FlutterPlugin, AbilityAware {
  private channel?: MethodChannel;
  private deviceType: string = deviceInfo.deviceType;
  private context?: common.UIAbilityContext;
  private avSession?: AVSession.AVSession;

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.context = binding.getAbility().context;
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "com.simplelive.app/intent");
    this.channel.setMethodCallHandler({
      onMethodCall: (call: MethodCall, result: MethodResult) => {
        switch (call.method) {
          case "enterFullscreen": {
            let needSet = Boolean(call.argument("needSet"));
            this.enterFullScreen(needSet);
            result.success("");
            break;
          }
          case "exitFullscreen": {
            this.exitFullScreen();
            result.success("");
            break;
          }
          case "saveFile": {
            let fileName = String(call.argument("fileName"));
            let bytes = call.argument("bytes") as Uint8Array;
            this.saveFile(fileName, bytes, result);
            break;
          }
          case "avSessionCreate": {
            this.avSessionCreate(result);
            break;
          }
          case "avSessionUpdate": {
            this.avSessionUpdate(call, result);
            break;
          }
          case "avSessionDestroy": {
            this.avSessionDestroy(result);
            break;
          }
          default:
            result.notImplemented();
            break;
        }
      }
    })
  }

  private enterFullScreen(needSet: boolean): void {
    window.getLastWindow(this.context).then((lastWindow) => {
      lastWindow.setSpecificSystemBarEnabled("status", false, true);
      lastWindow.setSpecificSystemBarEnabled("navigationIndicator", false, true);
      if (needSet) {
        lastWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_LANDSCAPE);
      } else {
        lastWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_UNSPECIFIED);
      }
      try {
        // 智慧多窗（横屏分屏），低版本系统不支持时忽略
        lastWindow.enableLandscapeMultiWindow();
      } catch (e) {
        let error = e as BusinessError;
        console.error(`enableLandscapeMultiWindow failed. Code: ${error.code}`);
      }
      lastWindow.maximize();
    }).catch((e: BusinessError) => {
      console.error(`enterFullscreen failed. Code: ${e.code}, message: ${e.message}`);
    })
  }

  private exitFullScreen(): void {
    window.getLastWindow(this.context).then((lastWindow) => {
      lastWindow.setSpecificSystemBarEnabled("status", true, true);
      lastWindow.setSpecificSystemBarEnabled("navigationIndicator", true, true);
      if (this.deviceType == "phone" && display.getFoldDisplayMode() != 1) {
        lastWindow.setPreferredOrientation(window.Orientation.USER_ROTATION_PORTRAIT);
      } else {
        lastWindow.setPreferredOrientation(window.Orientation.AUTO_ROTATION_UNSPECIFIED);
      }
      try {
        lastWindow.disableLandscapeMultiWindow();
      } catch (e) {
        let error = e as BusinessError;
        console.error(`disableLandscapeMultiWindow failed. Code: ${error.code}`);
      }
      lastWindow.recover();
    }).catch((e: BusinessError) => {
      console.error(`exitFullscreen failed. Code: ${e.code}, message: ${e.message}`);
    })
  }

  private saveFile(fileName: string, bytes: Uint8Array, result: MethodResult): void {
    if (!this.context) {
      result.error("no_context", "UIAbility context is null", null);
      return;
    }
    let options = new picker.DocumentSaveOptions();
    options.newFileNames = [fileName];
    let documentPicker = new picker.DocumentViewPicker(this.context);
    documentPicker.save(options).then((uris: Array<string>) => {
      if (uris == null || uris.length == 0) {
        // 用户取消
        result.success(null);
        return;
      }
      try {
        let file = fs.openSync(uris[0], fs.OpenMode.READ_WRITE);
        fs.writeSync(file.fd, bytes.buffer);
        fs.closeSync(file);
        result.success(uris[0]);
      } catch (e) {
        let error = e as BusinessError;
        result.error(`${error.code}`, `write file failed: ${error.message}`, null);
      }
    }).catch((e: BusinessError) => {
      result.error(`${e.code}`, e.message, null);
    })
  }

  private async avSessionCreate(result: MethodResult): Promise<void> {
    try {
      await this.avSessionDestroyQuietly();
      if (!this.context) {
        result.error("no_context", "UIAbility context is null", null);
        return;
      }
      let session: AVSession.AVSession =
        await AVSession.createAVSession(this.context, "simple_live", "audio");
      session.on('play', () => {
        this.channel?.invokeMethod("avSessionCommand", "play");
      });
      session.on('pause', () => {
        this.channel?.invokeMethod("avSessionCommand", "pause");
      });
      session.on('stop', () => {
        this.channel?.invokeMethod("avSessionCommand", "stop");
      });
      await session.activate();
      this.avSession = session;
      result.success(true);
    } catch (e) {
      let error = e as BusinessError;
      result.error(`${error.code}`, `createAVSession failed: ${error.message}`, null);
    }
  }

  private async avSessionUpdate(call: MethodCall, result: MethodResult): Promise<void> {
    let session: AVSession.AVSession | undefined = this.avSession;
    if (!session) {
      result.success(false);
      return;
    }
    try {
      let title: string = (call.argument("title") ?? "") as string;
      let artist: string = (call.argument("artist") ?? "") as string;
      let isPlaying: boolean = Boolean(call.argument("isPlaying"));
      let metadata: AVSession.AVMetadata = {
        assetId: "simple_live_current",
        title: title,
        artist: artist,
      };
      await session.setAVMetadata(metadata);
      let playbackState: AVSession.AVPlaybackState = {
        state: isPlaying
          ? AVSession.PlaybackState.PLAYBACK_STATE_PLAY
          : AVSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      };
      await session.setAVPlaybackState(playbackState);
      result.success(true);
    } catch (e) {
      let error = e as BusinessError;
      result.error(`${error.code}`, `updateAVSession failed: ${error.message}`, null);
    }
  }

  private async avSessionDestroy(result: MethodResult): Promise<void> {
    await this.avSessionDestroyQuietly();
    result.success(true);
  }

  private async avSessionDestroyQuietly(): Promise<void> {
    let session: AVSession.AVSession | undefined = this.avSession;
    this.avSession = undefined;
    if (!session) {
      return;
    }
    try {
      session.off('play');
      session.off('pause');
      session.off('stop');
      await session.destroy();
    } catch (e) {
      let error = e as BusinessError;
      console.error(`destroyAVSession failed. Code: ${error.code}`);
    }
  }

  getUniqueClassName(): string {
    return "MethodCallPlugin"
  }

  onDetachedFromAbility(): void {
  }

  onDetachedFromEngine(): void {
    this.channel?.setMethodCallHandler(null);
  }
}
