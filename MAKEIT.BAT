@echo off

if not exist rsrc.rc goto over1
c:\MASM32\BIN\Rc.exe /v rsrc.rc
c:\MASM32\BIN\Cvtres.exe /machine:ix86 rsrc.res
:over1

if exist %1.obj del bv2heatmon.obj
if exist %1.exe del bv2heatmon.exe

c:\MASM32\BIN\Ml.exe /c /coff bv2heatmon.asm
if errorlevel 1 goto errasm

if not exist rsrc.obj goto nores

c:\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS bv2heatmon.obj rsrc.obj 
if errorlevel 1 goto errlink

dir videoo
goto TheEnd

:nores
c:\MASM32\BIN\Link.exe /SUBSYSTEM:WINDOWS bv2heatmon.obj
if errorlevel 1 goto errlink
dir %1
goto TheEnd

:errlink
echo _
echo Link error
goto TheEnd

:errasm
echo _
echo Assembly Error
goto TheEnd

:TheEnd

pause

