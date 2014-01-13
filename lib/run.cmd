@ECHO OFF

SET CURRENTDIR=%~dp0
SET AutoHammer=%CURRENTDIR%\deps\autohammer
SET TCLSH86T="C:\Program Files\HammerDB-2.15\bin\tclsh86t.exe"

CD %AutoHammer%

%TCLSH86T% %*

CD %CURRENTDIR%