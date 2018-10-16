@echo off

if "%CMDEXTVERSION%" == "" goto ERRCmdExt

if not "%1" == "/?" goto BEGIN
echo Create the CodeBase static library.
echo.
echo c4lib_link [/D] [/I dir] [/N name] [/O dir] [/link opt [/link opt [...]]]
echo            ^{@source.lst ^| source.c^}
echo.
echo   /D          Generate debugging information.
echo   /I          Specifies the directory where the intermediate files
echo               (e.g. *.obj) are located. If not provided, intermediate files
echo               are assumed to be in the current directory.
echo   /N          Specifies name of the output LIB. If not provided, c4lib.lib
echo               is used.
echo   /O          Specifies where all output files will be placed. If not
echo               provided, output files are placed in the same directory as the
echo               intermediate directory.
echo   /link       An options passed directly to the linker.
echo   @source.lst A text file containing a list of source file names, one per
echo               line, which have been compiled into .obj files. Lines beginning
echo               with # are ignored.
echo   source.c    A single source file which has been compiled into a .obj file.
echo.
echo Errors and warnings from the link are placed in the file 'OUT' located in the
echo output directory.
echo.
echo Exit codes:
echo   0 Success
echo   1 The link could not be performed. Check the file called 'out' for errors.
goto :EOF

:BEGIN
setlocal
echo Preparing to link...

REM set defaults
set DEBUG=
set INTERMEDIATE=%cd%
set OUTPUT=
set LIBNAME=c4lib.lib
set LINKOPTS=
set LINKLIST=%TEMP%\L%RANDOM%.tmp

if exist %LINKLIST% del %LINKLIST%

:ReadParameters
if /I "%~1" == "/D" (
   set DEBUG="T"
   shift
   goto ReadParameters
)
if /I "%~1" == "/I" (
   set INTERMEDIATE=%~f2
   shift
   shift
   goto ReadParameters
)
if /I "%~1" == "/N" (
   set LIBNAME=%~2
   shift
   shift
   goto ReadParameters
)
if /I "%~1" == "/O" (
   set OUTPUT=%~f2
   shift
   shift
   goto ReadParameters
)
if /I "%~1" == "/LINK" (
   set LINKOPTS=%LINKOPTS% %~2
   shift
   shift
   goto ReadParameters
)
set PERCENT1=%~1
if "%PERCENT1:~0,1%" == "@" (
   @REM The parameter is a list file name.
   REM for each line in the list
   for /F "eol=# tokens=*" %%f in (%PERCENT1:~1%) do (
      call :ToList %%f %LINKLIST%
   )
   shift
   goto ReadParameters
)
if not "%~1" == "" (
   @REM must be a file name
   echo %~1 >> %LINKLIST%
   shift
   goto ReadParameters
)
REM end of parameter checking

if not exist %LINKLIST% (
   echo No source files provided. > "%OUTPUT%\out"
   type "%OUTPUT%\out"
   exit /b 1
)

if defined DEBUG (
   @REM set DEBOPTS=/DEBUGTYPE:FULL
   set DEBOPTS=/DEBUGTYPE:CV
) else (
   set DEBOPTS=
)

set STARTINGDIRECTORY=%cd%

if not defined OUTPUT set OUTPUT=%INTERMEDIATE%

REM change to output directory
cd /d "%OUTPUT%"
if ERRORLEVEL 1 exit /b %ERRORLEVEL%

del "%LIBNAME%" 2> nul
@echo on
lib "/OUT:%LIBNAME%" %DEBOPTS% @%LINKLIST% > OUT
@echo off

del %LINKLIST%

if not exist %LIBNAME% (
   echo *** Unable to build %LIBNAME%
   exit /b 1
)

goto :EOF
REM end of main script body


:ToList
   @REM Description: given a source file name, append
   @REM    the corresponding object file name to a list file.
   @REM %1 The name of the source file.
   @REM %2 The name of the list file.
   echo "%INTERMEDIATE%\%~n1.obj" >> %2
   goto :EOF
REM end ToList


:ERRCmdExt
   echo Unable to run. Command extensions are not enabled.
