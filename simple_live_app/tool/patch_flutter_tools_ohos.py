# -*- coding: utf-8 -*-
"""
给 flutter-ohos SDK (CPF-Flutter/flutter_flutter, oh-3.41.9) 打两个补丁：

补丁 1（全平台）：让 ohos 构建把 NativeAssetsManifest.json 打进 flutter_assets。
背景：ohos 引擎运行时通过 flutter_assets/NativeAssetsManifest.json 解析
native assets 映射（如 dart_quickjs 的 libdart_quickjs.so），但
flutter_tools 的 ohos.dart 在 copyAssets 时没有下发该文件（android/macos
均有），导致包运行时报:
  "No asset with id ... found. No available native assets."

补丁 2（仅 Windows 生效）：修复 flutter_tools 直接 spawn 裸 'ohpm' 的问题。
背景：ohpmInstall 用 ['ohpm', 'install', '--all'] 直接起进程，Windows 上
ohpm 只有 ohpm.bat（CreateProcess 不认无扩展名脚本），spawn 必报
"系统找不到指定的文件"。补丁改为优先调用项目内的修复版垫片
ohos/build-tools/ohpm/bin/ohpm.bat（见 ohos/hvigorw.bat 的镜像逻辑，
DevEco 原版 ohpm.bat 在 Dart 派生的 cmd 环境下有批处理无限递归 bug）。

用法（在补丁丢失或升级 SDK 后执行一次）:
  python tool/patch_flutter_tools_ohos.py [flutter_ohos_sdk_path]
默认 SDK 路径取 FLUTTER_OMHOS_ROOT 环境变量或 D:/flutter_flutter。

补丁后需删除 bin/cache/flutter_tools.stamp 与 flutter_tools.snapshot
（脚本会自动删除）以触发工具快照重建。
"""
import io
import os
import sys

DEFAULT_SDK = os.environ.get("FLUTTER_OMHOS_ROOT", r"D:\flutter_flutter")
TARGET = "packages/flutter_tools/lib/src/build_system/targets/ohos.dart"
TARGET2 = "packages/flutter_tools/lib/src/ohos/hvigor.dart"

OLD_IMPORT = "import '../../globals.dart' as globals show xcode;"
NEW_IMPORT = ("import '../../devfs.dart';\n"
              "import '../../globals.dart' as globals show xcode;")

OLD_CALL = """    final Depfile assetDepfile = await copyAssets(
      environment,
      outputDirectory,
      dartHookResult: dartHookResult,
      targetPlatform: TargetPlatform.ohos,
      buildMode: buildMode,
      flavor: environment.defines[kFlavor],
    );"""
NEW_CALL = """    final Depfile assetDepfile = await copyAssets(
      environment,
      outputDirectory,
      dartHookResult: dartHookResult,
      targetPlatform: TargetPlatform.ohos,
      buildMode: buildMode,
      flavor: environment.defines[kFlavor],
      additionalContent: <String, DevFSContent>{
        'NativeAssetsManifest.json': DevFSFileContent(
          environment.buildDir.childFile('native_assets.json'),
        ),
      },
    );"""

OLD_OHPM = """  final List<String> installCmd = <String>['ohpm', 'install', '--all'];"""
NEW_OHPM = """  // patched: windows has no ohpm.exe, bare 'ohpm' cannot be spawned;
  // prefer the project's fixed shim (ohos/build-tools/ohpm/bin/ohpm.bat)
  List<String> installCmd;
  if (isWindows) {
    final String localOhpm = globals.fs.path.join(
        workingDirectory, 'build-tools', 'ohpm', 'bin', 'ohpm.bat');
    installCmd = globals.fs.file(localOhpm).existsSync()
        ? <String>[localOhpm, 'install', '--all']
        : <String>['cmd', '/c', 'ohpm.bat', 'install', '--all'];
  } else {
    installCmd = <String>['ohpm', 'install', '--all'];
  }"""


def patch_file(sdk, rel, old, new, label):
    path = os.path.join(sdk, rel)
    if not os.path.isfile(path):
        print("[ERROR] not found: %s" % path)
        return False
    s = io.open(path, encoding="utf-8").read()
    if new in s:
        print("[OK] already patched (%s): %s" % (label, path))
        return True
    if s.count(old) != 1:
        print("[ERROR] anchor not found or not unique (%s): %s" % (label, path))
        return False
    io.open(path, "w", encoding="utf-8", newline="").write(s.replace(old, new, 1))
    print("[OK] patched (%s): %s" % (label, path))
    return True


def main():
    sdk = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SDK

    ok1 = patch_file(sdk, TARGET, OLD_IMPORT, NEW_IMPORT, "imports")
    s_path = os.path.join(sdk, TARGET)
    if ok1:
        ok1 = patch_file(sdk, TARGET, OLD_CALL, NEW_CALL, "native assets manifest")
    ok2 = patch_file(sdk, TARGET2, OLD_OHPM, NEW_OHPM, "windows ohpm spawn")

    if not (ok1 and ok2):
        sys.exit(1)

    for f in ("bin/cache/flutter_tools.stamp", "bin/cache/flutter_tools.snapshot"):
        p = os.path.join(sdk, f)
        if os.path.exists(p):
            os.remove(p)
            print("[OK] removed %s (tools snapshot will rebuild on next run)" % f)


if __name__ == "__main__":
    main()
