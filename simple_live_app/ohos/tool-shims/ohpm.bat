@echo off
@rem ---------------------------------------------------------------------------
@rem ohpm replacement for Windows builds (delegates to pm-cli.js).
@rem
@rem The stock ohpm.bat shipped with DevEco Studio contains a command line
@rem parsing routine that recurses infinitely when the script is spawned
@rem through cmd /c with a quoted path (as hvigor does), aborting with
@rem "BATCH RECURSION exceeds STACK limits".
@rem
@rem hvigorw.js resolves the ohpm binary as <hvigor>/../../ohpm/bin/ohpm.bat,
@rem so the project layout under ohos/build-tools makes hvigor pick up this
@rem shim instead of the broken stock script. See ohos/hvigorw.bat.
@rem NOTE: keep this file ASCII only.
@rem ---------------------------------------------------------------------------

setlocal enabledelayedexpansion

set "OHPM_HOME="
if defined TOOL_HOME set "OHPM_HOME=%TOOL_HOME%\tools\ohpm\bin"
if not exist "%OHPM_HOME%\pm-cli.js" set "OHPM_HOME=C:\Program Files\Huawei\DevEco Studio\tools\ohpm\bin"
if not exist "%OHPM_HOME%\pm-cli.js" (
  echo ERROR: ohpm pm-cli.js not found. Please install DevEco Studio or set TOOL_HOME.
  exit /b 1
)

@rem Drop the first argument when it is a path to this script itself,
@rem which happens when the caller passes a quoted script path through cmd /c.
set "ARG1=%~1"
if not "%ARG1%"=="" (
  echo %ARG1%| findstr /I /C:"ohpm.bat" >NUL 2>&1
  if not errorlevel 1 shift
)

@rem Rebuild the argument list (shift does not affect %*).
set "PARAMS="
:parse
if "%~1"=="" goto run
set "PARAMS=!PARAMS! "%~1""
shift
goto parse

:run
node "%OHPM_HOME%\pm-cli.js" %PARAMS%
endlocal & exit /b %ERRORLEVEL%
