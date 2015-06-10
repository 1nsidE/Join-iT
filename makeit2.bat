@echo off

SET POTOOLS="potools\polink.exe"
SET PROJECTNAME=Join-iT
SET MASMBIN=C:\MASM32\bin
SET MASMINCLUDE=C:\MASM32\include
SET MASMLIB=C:\MASM32\lib

%MASMBIN%\Ml.exe /I %MASMINCLUDE% /c /coff %PROJECTNAME%.asm
%MASMBIN%\rc.exe /x %PROJECTNAME%.rc
polink.exe /LIBPATH:%MASMLIB% /SUBSYSTEM:WINDOWS /MERGE:.rsrc=.text /MERGE:.data=.text %PROJECTNAME%.obj %PROJECTNAME%.res

del *.obj
del *.res

echo.
pause