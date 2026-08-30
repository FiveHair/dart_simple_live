# -*- coding: utf-8 -*-
"""
给 flutter-ohos SDK (CPF-Flutter/flutter_flutter, oh-3.41.9) 打补丁：
让 ohos 的 debug 构建把 NativeAssetsManifest.json 打进 flutter_assets。

背景：ohos 引擎运行时通过 flutter_assets/NativeAssetsManifest.json 解析
native assets 映射（如 dart_quickjs 的 libdart_quickjs.so），但
flutter_tools 的 ohos.dart 在 copyAssets 时没有下发该文件（android/macos
均有），导致 debug 包运行时报:
  "No asset with id ... found. No available native assets."

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


def main():
    sdk = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SDK
    path = os.path.join(sdk, TARGET)
    if not os.path.isfile(path):
        print("[ERROR] not found: %s" % path)
        sys.exit(1)

    s = io.open(path, encoding="utf-8").read()

    if NEW_CALL in s:
        print("[OK] already patched: %s" % path)
        return

    if OLD_CALL not in s or OLD_IMPORT not in s:
        print("[ERROR] anchor not found (SDK version changed? please patch manually)")
        sys.exit(1)

    s = s.replace(OLD_IMPORT, NEW_IMPORT, 1)
    s = s.replace(OLD_CALL, NEW_CALL, 1)
    io.open(path, "w", encoding="utf-8", newline="").write(s)
    print("[OK] patched: %s" % path)

    for f in ("bin/cache/flutter_tools.stamp", "bin/cache/flutter_tools.snapshot"):
        p = os.path.join(sdk, f)
        if os.path.exists(p):
            os.remove(p)
            print("[OK] removed %s (tools snapshot will rebuild on next run)" % f)


if __name__ == "__main__":
    main()
