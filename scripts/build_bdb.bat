echo off
SETLOCAL
SET EL=0
echo ------ bdb -----

:: guard to make sure settings have been sourced
IF "%ROOTDIR%"=="" ( echo "ROOTDIR variable not set" && GOTO DONE )

cd %PKGDIR%
CALL curl -s -S -f -O -L -k --retry 3 http://download.oracle.com/berkeley-db/db-%BDB_VERSION%.NC.tar.gz
IF %ERRORLEVEL% NEQ 0 GOTO ERROR

if EXIST bdb (
  echo found extracted sources
)


SETLOCAL ENABLEDELAYEDEXPANSION
if NOT EXIST bdb (
  echo extracting
  CALL tar xfz db-%BDB_VERSION%.NC.tar.gz
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  rename db-%BDB_VERSION%.NC bdb
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
cd %PKGDIR%\bdb
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
  ECHO patching ...
  patch -N -p1 < %PATCHES%/bdb-%BDB_VERSION%.diff || true
  IF !ERRORLEVEL! NEQ 0 GOTO ERROR
)
ENDLOCAL


cd %PKGDIR%\bdb\msvc
IF %ERRORLEVEL% NEQ 0 GOTO ERROR


msbuild ^
.\bdb.sln ^
/target:bdb ^
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
echo ----------ERROR bdb --------------

:DONE

cd %ROOTDIR%
EXIT /b %EL%
