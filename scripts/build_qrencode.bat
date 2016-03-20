echo off
SETLOCAL
SET EL=0
echo ------ qrencode -----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL curl -s -S -f -O -L -k --retry 3 http://fukuchi.org/works/qrencode/qrencode-%QRENCODE_VERSION%.tar.bz2
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

if EXIST qrencode (
  echo found extracted sources
)


SETLOCAL ENABLEDELAYEDEXPANSION
if NOT EXIST qrencode (
  echo extracting
  CALL tar xfj qrencode-%QRENCODE_VERSION%.tar.bz2
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  rename qrencode-%QRENCODE_VERSION% qrencode
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
cd %PKGDIR%\qrencode
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  ECHO patching ...
  patch -N -p1 < %PATCHES%/qrencode-%QRENCODE_VERSION%.diff || true
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
)
ENDLOCAL


cd %PKGDIR%\qrencode\msvc
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


msbuild ^
.\qrencode.sln ^
/target:qrencode ^
/p:ForceImportBeforeCppTargets=%ROOTDIR%\scripts\force-debug-information-for-sln.props ^
/nologo ^
/m:%NUMBER_OF_PROCESSORS% ^
/toolsversion:%TOOLS_VERSION% ^
/p:BuildInParallel=true ^
/p:Configuration=%BUILD_TYPE% ^
/p:Platform=%BUILDPLATFORM% ^
/p:PlatformToolset=%PLATFORM_TOOLSET%
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


GOTO DONE

:ERROR
SET EL=%ERRORLEVEL%
echo ----------ERROR qrencode --------------

:DONE

cd %ROOTDIR%
EXIT /b %EL%
