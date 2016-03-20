echo off
SETLOCAL
SET EL=0
echo ------ miniupnpc -----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL curl -s -S -f -O -L -k --retry 3 http://miniupnp.free.fr/files/miniupnpc-%MINIUPNPC_VERSION%.tar.bz2
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

if EXIST miniupnpc (
  echo found extracted sources
)


SETLOCAL ENABLEDELAYEDEXPANSION
if NOT EXIST miniupnpc (
  echo extracting
  CALL tar xfj miniupnpc-%MINIUPNPC_VERSION%.tar.bz2
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  rename miniupnpc-%MINIUPNPC_VERSION% miniupnpc
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
cd %PKGDIR%\miniupnpc
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  ECHO patching ...
  patch -N -p1 < %PATCHES%/miniupnpc-%MINIUPNPC_VERSION%.diff || true
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
)
ENDLOCAL


cd %PKGDIR%\miniupnpc\msvc
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


msbuild ^
.\miniupnpc.sln ^
/target:miniupnpc ^
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
echo ----------ERROR miniupnpc --------------

:DONE

cd %ROOTDIR%
EXIT /b %EL%
