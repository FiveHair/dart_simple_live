# -*- coding: utf-8 -*-
"""
校验 ohos HAP 产物中的 native 库完整性。

背景：CI 环境若跳过了 git LFS 下载（或 LFS 服务端缺文件），依赖仓库中的
大体积 .so（如 libmpv.so.2）会以 133 字节的 LFS 指针文本混入 HAP，
安装后运行白屏。此脚本在打包后校验 HAP 内 libs/<abi>/ 下所有 .so 均为真实 ELF 文件。
"""
import sys
import zipfile


def main():
    if len(sys.argv) != 2:
        print("usage: verify_ohos_hap.py <hap>")
        sys.exit(2)

    hap = sys.argv[1]
    z = zipfile.ZipFile(hap)
    failed = []
    checked = 0
    for name in z.namelist():
        # 匹配 libs/<abi>/libxxx.so 与 libxxx.so.2 这类带版本号的库
        if not name.startswith("libs/") or ".so" not in name.split("/")[-1]:
            continue
        head = z.read(name)[:64]
        checked += 1
        # ELF magic: 0x7f 'E' 'L' 'F'
        if head[:4] != b"\x7fELF":
            failed.append(name)
            print("BAD  %s (%d bytes, head=%r)" % (
                name, z.getinfo(name).file_size, head[:32]))
        else:
            print("OK   %s (%d bytes)" % (name, z.getinfo(name).file_size))

    if checked == 0:
        print("no shared libraries found in HAP!")
        sys.exit(1)
    if failed:
        print("FAILED: LFS pointer / non-ELF libraries found: %s" % failed)
        sys.exit(1)
    print("all %d libraries are valid ELF" % checked)


if __name__ == "__main__":
    main()
