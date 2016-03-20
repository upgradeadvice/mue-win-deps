@echo off

:::::::::::::: USAGE
:: see bottom of this file

:::::::::::::: OVERRIDABLE PARAMETERS
set TARGET_ARCH=64
SET MAPNIKBRANCH=master
SET MAPNIKGYPBRANCH=master
SET NODEMAPNIKBRANCH=master
SET SKIP_FAILED_PATCH=false
SET FASTBUILD=1
SET RUNCODEANALYSIS=0
SET SHAREDTMPBIN=
SET SHAREDPKGSRC=
SET MAPNIK_BUILD_TESTS=1
SET PACKAGEDEPS=0
SET PACKAGEMAPNIK=1
SET PUBLISHMAPNIKSDK=0
SET PUBLISHNODEMAPNIK=0
SET PACKAGEDEBUGSYMBOLS=0
SET VERBOSE=0
SET IGNOREFAILEDTESTS=0
::local meaning, built by these scripts
SET PREFER_LOCAL_NODE_EXE=1
::node-mapnik: use local mapnik sdk or download sdk defined for AppVeyor
SET USE_LOCAL_MAPNIK_SDK=1
SET BUNDLE_RUNTIME=0

SET ZLIB_VERSION=1.2.8
SET PROTOBUF_VERSION=2.6.1
SET BDB_VERSION=2.0.3
SET MINIUPNPC_VERSION=3.4.2
SET QRENCODE_VERSION=3.4.4
SET BUILD_STATIC=0


:::::::::::::: OVERRIDE PARAMETERS
:NEXT-ARG

IF '%1'=='' GOTO ARGS-DONE
ECHO setting %1
SET %1
SHIFT
GOTO NEXT-ARG

:ARGS-DONE


::BAIL OUT IF DEBUG or VS2013
IF DEFINED BUILD_TYPE IF NOT "%BUILD_TYPE%"=="Release" (SET BUILD_TYPE=) && ECHO only Release builds supported! && SET EL=1 && GOTO ERROR
IF DEFINED TOOLS_VERSION IF NOT "%TOOLS_VERSION%"=="14.0" (SET TOOLS_VERSION=) && ECHO only Visual Studio 2015 supported! && SET EL=1 && GOTO ERROR


:::::::::::::: FIXED PARAMETERS
SET BUILD_TYPE=Release
SET TOOLS_VERSION=14.0
SET RUNTIME_VERSION=vcredist-VS2015



::::::::::::::: DO STUFF

REM IF NOT EXIST C:\Python27 ( ECHO C:\Python27 not found && GOTO ERROR )


REM IF EXIST "C:\Program Files (x86)\Git\bin" SET PATH=C:\Program Files (x86)\Git\bin;%PATH%
REM IF EXIST "C:\Program Files\Git\usr\bin" SET PATH=C:\Program Files\Git\usr\bin;%PATH%
REM IF EXIST "C:\Program Files\Git\bin" SET PATH=C:\Program Files\Git\bin;%PATH%
REM WHERE git >NUL
REM IF %ERRORLEVEL% NEQ 0 (ECHO git not found && GOTO ERROR)
REM WHERE curl >NUL
REM IF %ERRORLEVEL% NEQ 0 (ECHO curl not found, is git installed && GOTO ERROR)


if "%TARGET_ARCH%" == "32" (
  SET BUILDPLATFORM=Win32
  SET BOOSTADDRESSMODEL=32
  SET WEBP_PLATFORM=x86
  SET PLATFORMX=x86
)

if "%TARGET_ARCH%" == "64" (
  SET BUILDPLATFORM=x64
  SET BOOSTADDRESSMODEL=64
  SET WEBP_PLATFORM=x64
  SET PLATFORMX=x64
)

SET current_script_dir=%~dp0
SET ROOTDIR=%current_script_dir%
SET PKGDIR=%ROOTDIR%packages
IF NOT EXIST %PKGDIR% MKDIR %PKGDIR%
SET PATCHES=%ROOTDIR%patches
IF NOT EXIST %PATCHES% MKDIR %PATCHES%

REM ::TODO: see what we can use from mysysgit
REM ::wget cmake
REM SET PATH=C:\Windows\System32\WindowsPowershell\v1.0;%PATH%
REM SET PATH=C:\Python27;%PATH%
REM SET PATH=C:\Python27\Scripts;%PATH%
REM SET PATH=%CD%\tmp-bin\cmake-3.1.0-win32-x86\bin;%PATH%
REM SET PATH=%CD%\tmp-bin\nasm-2.11.08;%PATH%
REM SET PATH=%CD%\tmp-bin\gnu-win-tools;%PATH%
REM SET PATH=%CD%\tmp-bin\ragel\%PLATFORMX%;%PATH%
REM ::always use 7z x64, 32bit version cannot handle size of mapnik + PDBs
REM SET PATH=%CD%\tmp-bin\7zip\x64;%PATH%
REM SET PATH=%CD%\tmp-bin\ddt\%PLATFORMX%;%PATH%
REM SET PATH=%CD%\tmp-bin\scriptcs;%PATH%
REM SET PATH=%CD%\tmp-bin;%PATH%
REM ::set path to make.exe at last.
REM ::make.exe that comes with gnu-win-tools cannot compile cairo
REM SET PATH=%CD%\tmp-bin\make;%PATH%


SET MSVC_VER=1900
SET PLATFORM_TOOLSET=v140
REM :: CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x86
REM :: >..\..\src\agg\process_markers_symbolizer.cpp(108): fatal error C1060: compiler is out of heap space [C:\dev2\mapnik-dependencies\packages\mapnik-3.x\mapnik-gyp\build\mapnik.vcxproj]
REM :: configure this Command Prompt window for 64-bit command-line builds that target x86 platforms
REM :: http://msdn.microsoft.com/en-us/library/x4d2c09s.aspx
IF "%TARGET_ARCH%" == "32" CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64_x86
IF "%TARGET_ARCH%" == "64" CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" amd64
IF %ERRORLEVEL% NEQ 0 ECHO error calling vcvarsall.bat && GOTO ERROR

WHERE msbuild >NUL
IF %ERRORLEVEL% NEQ 0 ECHO msbuild not found && GOTO ERROR

CD %ROOTDIR%

REM IF NOT EXIST tmp-bin (
REM   CALL curl -k -O https://mapbox.s3.amazonaws.com/windows-builds/windows-build-deps/windows-builds-tmp-bin.exe
REM   CALL windows-builds-tmp-bin.exe -y -o"."
REM )
REM IF %ERRORLEVEL% NEQ 0 GOTO ERROR
REM
REM python setuptools-available.py
REM IF %ERRORLEVEL% NEQ 0 (
REM   ECHO Please install setuptools for python!
REM   ECHO see https://pypi.python.org/pypi/setuptools#installation-instructions
REM   GOTO ERROR
REM )
REM
REM if NOT EXIST C:\Python27\Scripts\aws (
REM   echo. && echo getting aws-cli
REM   ddt /Q aws-cli
REM   git clone --depth=1 https://github.com/aws/aws-cli.git
REM   cd aws-cli
REM   python setup.py install
REM   cd ..
REM )


REM :: need PACKAGEMAPNIK for PUBLISHMAPNIKSDK to work
REM IF %PUBLISHMAPNIKSDK% NEQ 0 IF %PACKAGEMAPNIK% EQU 0 GOTO PUBLISHMAPNIKSDKERROR
REM
REM IF %PUBLISHMAPNIKSDK% NEQ 0 GOTO CHECKAWS
REM IF %PUBLISHNODEMAPNIK% NEQ 0 GOTO CHECKAWS
REM
REM GOTO CHECKPOWERSHELL
REM
REM
REM :CHECKAWS
REM ECHO.
REM ECHO ------------checking for AWS-CLI ---------
REM ECHO checking for AWS_ACCESS_KEY_ID
REM IF "%AWS_ACCESS_KEY_ID%" == "" GOTO AWSNOKEYS
REM ECHO checking for AWS_SECRET_ACCESS_KEY
REM IF "%AWS_SECRET_ACCESS_KEY%" == "" GOTO AWSNOKEYS
REM ECHO AWS keys found
REM CALL "C:\Program Files\Amazon\AWSCLI\aws.exe" --version
REM ::9009 -> "<CMD> is not recognized as an internal or external command, operable program or batch file."
REM IF %ERRORLEVEL% EQU 9009 GOTO AWSNOTAVAILABLE
REM IF %ERRORLEVEL% NEQ 0 GOTO AWSUNKNOWNERROR
REM ECHO AWS-CLI OK
REM ECHO.


REM :CHECKPOWERSHELL
REM ECHO.
REM ECHO ------------ checking for Powershell ------------
REM ECHO Powershell version^:
REM powershell $PSVersionTable.PSVersion
REM IF %ERRORLEVEL% NEQ 0 GOTO PSNOTAVAILABLE
REM
REM FOR /F "tokens=*" %%i in ('powershell Get-ExecutionPolicy') do SET PSPOLICY=%%i
REM ECHO Powershell execution policy^: %PSPOLICY%
REM IF NOT "%PSPOLICY%"=="Unrestricted" powershell Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Unrestricted -Force
REM IF %ERRORLEVEL% NEQ 0 GOTO PSPOLICYERROR
REM FOR /F "tokens=*" %%i in ('powershell Get-ExecutionPolicy') do SET PSPOLICY=%%i
REM ECHO Powershell execution policy now is^: %PSPOLICY%
REM
REM ::install scriptcs
REM powershell .\scripts\get-scriptcs.ps1
REM IF %ERRORLEVEL% NEQ 0 GOTO ERROR
REM WHERE scriptcs >NUL
REM IF %ERRORLEVEL% NEQ 0 ECHO scriptcs not found && GOTO ERROR

GOTO DONE

:USAGE
ECHO usage:
ECHO settings.bat ^<target_arch^> ^<tools_version^> ^<build_type^>
ECHO settings.bat 32^|64 12^|14 Release^|Debug
EXIT /b 1

GOTO DONE

:ERROR
ECHO !!!!!!!! ===== ERROR ==== !!!!!!!!
ECHO builds cannot be run unless settings.bat finished successfully
CD %ROOTDIR%
EXIT /b 1

:DONE

ECHO. && ECHO ------ PARAMETERS ------
ECHO TARGET_ARCH^: %TARGET_ARCH%
ECHO TOOLS_VERSION^: %TOOLS_VERSION%
ECHO BUILD_TYPE^: %BUILD_TYPE%
ECHO FASTBUILD^: %FASTBUILD%
ECHO SUPERFASTBUILD^: %SUPERFASTBUILD%
ECHO SKIP_FAILED_PATCH^: %SKIP_FAILED_PATCH%
REM ECHO.
REM ECHO MAPNIKBRANCH^: %MAPNIKBRANCH%
REM ECHO MAPNIKGYPBRANCH^: %MAPNIKGYPBRANCH%
REM ECHO NODEMAPNIKBRANCH^: %NODEMAPNIKBRANCH%
REM ECHO.
REM ECHO PACKAGEMAPNIK^: %PACKAGEMAPNIK%
REM ECHO PACKAGEDEBUGSYMBOLS^: %PACKAGEDEBUGSYMBOLS%
REM ECHO PUBLISHMAPNIKSDK^: %PUBLISHMAPNIKSDK%
REM ECHO PUBLISHNODEMAPNIK^: %PUBLISHNODEMAPNIK%


echo. && echo building within %current_script_dir% && ECHO. &&ECHO.

REM echo ------ USAGE ------
REM echo Calling "scripts\build" will run with above default parameters.
REM echo Parameters can be overriden, see top of source of this file for
REM echo overridable parameters. && ECHO.
REM echo Override like this (parameters MUST be quoted!)^: && ECHO.
REM echo settings "MAPNIKBRANCH=mybranch" "GDAL_VERSION=2.0.1" "SKIP_FAILED_PATCH=true"
REM echo.


GOTO THENEND
REM
REM
REM :PUBLISHMAPNIKSDKERROR
REM ECHO.
REM ECHO !!!
REM ECHO parameter mismatch!!
REM ECHO PUBLISHMAPNIKSDK=1 needs PACKAGEMAPNIK=1
REM ECHO !!!
REM ECHO.
REM GOTO ERROR
REM
REM
REM :AWSNOKEYS
REM ECHO.
REM ECHO !!!
REM ECHO AWS keys not set!!
REM ECHO check AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS
REM ECHO !!!
REM ECHO.
REM GOTO ERROR
REM
REM
REM :AWSUNKNOWNERROR
REM ECHO.
REM ECHO !!!
REM ECHO unexpected error calling AWS CLI!!
REM ECHO is AWS CLI installed
REM ECHO !!!
REM ECHO.
REM GOTO ERROR
REM
REM :AWSNOTAVAILABLE
REM ECHO.
REM ECHO !!!
REM ECHO AWS CLI not found!!
REM ECHO check installation and availabilty on PATH
REM ECHO !!!
REM ECHO.
REM GOTO ERROR
REM
REM
REM :PSNOTAVAILABLE
REM ECHO.
REM ECHO !!!!
REM ECHO Powershell is not available!!!
REM ECHO check PATH and if it is installed
REM ECHO !!!!
REM ECHO.
REM GOTO ERROR
REM
REM :PSPOLICYERROR
REM ECHO.
REM ECHO !!!!
REM ECHO Could not set Powershell execution policy to 'Unrestricted'
REM ECHO !!!!
REM ECHO.
REM GOTO ERROR



:THENEND
