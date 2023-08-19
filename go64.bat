@echo off

if not defined DevEnvDir (
  call "%ProgramFiles(x86)%\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvarsall.bat" x86_x64
)

del app.exe

c:\harbour64\bin\hbmk2 app.hbp -comp=msvc64

IF ERRORLEVEL 1 GOTO COMPILEERROR

del app.exp
del app.lib

@cls
app.exe

GOTO EXIT

:COMPILEERROR

echo *** Error 

pause

:EXIT