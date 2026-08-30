@echo off
@rem ---------------------------------------------------------------------------
@rem hvigorw wrapper for Windows.
@rem
@rem 1. The flutter ohos toolchain calls hvigorw.bat inside the project first,
@rem    so this script is the entry point for ohos builds on Windows.
@rem 2. DevEco Studio's hvigorw.js hardcodes the ohpm binary as
@rem    <hvigor>/../../ohpm/bin/ohpm.bat. The stock ohpm.bat has an infinite
@rem    batch-recursion bug when spawned through cmd /c (which hvigor does),
@rem    aborting with "BATCH RECURSION exceeds STACK limits".
@rem    Node resolves the main script to its real path, so a junction is not
@rem    enough: we mirror DevEco's hvigor directory into ohos/build-tools
@rem    (gitignored, one-time robocopy) and place our fixed ohpm shim beside
@rem    it, matching the layout hvigorw.js expects:
@rem      ohos/build-tools/hvigor/...        (copy of DevEco tools/hvigor)
@rem      ohos/build-tools/ohpm/bin/ohpm.bat (copy of tool-shims/ohpm.bat)
@rem NOTE: keep this file ASCII only.
@rem ---------------------------------------------------------------------------

setlocal
set "DEVECO_HOME="
if defined TOOL_HOME set "DEVECO_HOME=%TOOL_HOME%"
if not exist "%DEVECO_HOME%\tools\hvigor\bin\hvigorw.js" set "DEVECO_HOME=C:\Program Files\Huawei\DevEco Studio"
if not exist "%DEVECO_HOME%\tools\hvigor\bin\hvigorw.js" (
  echo ERROR: DevEco Studio hvigor not found. Please install DevEco Studio or set TOOL_HOME.
  exit /b 1
)

set "BUILD_TOOLS=%~dp0build-tools"
if not exist "%BUILD_TOOLS%" mkdir "%BUILD_TOOLS%"
if not exist "%BUILD_TOOLS%\hvigor\bin\hvigorw.js" (
  echo Mirroring DevEco hvigor into %BUILD_TOOLS%\hvigor ^(one time, ~260MB^) ...
  robocopy "%DEVECO_HOME%\tools\hvigor" "%BUILD_TOOLS%\hvigor" /E /NFL /NDL /NJH /NJS /NC /NS >NUL
  if not exist "%BUILD_TOOLS%\hvigor\bin\hvigorw.js" (
    echo ERROR: failed to copy hvigor from DevEco Studio.
    exit /b 1
  )
)

if not exist "%BUILD_TOOLS%\ohpm\bin" mkdir "%BUILD_TOOLS%\ohpm\bin"
copy /y "%~dp0tool-shims\ohpm.bat" "%BUILD_TOOLS%\ohpm\bin\ohpm.bat" >NUL

where node >NUL 2>&1
if errorlevel 1 (
  echo ERROR: node not found in PATH. Add DevEco Studio's tools\node\bin to PATH.
  exit /b 1
)

node "%BUILD_TOOLS%\hvigor\bin\hvigorw.js" %*
endlocal & exit /b %ERRORLEVEL%
