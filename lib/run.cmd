@ECHO OFF

SET CURRENTDIR=%~dp0
SET SPECDIR=%CURRENTDIR%\..\specs
SET AUTOHAMMER=%CURRENTDIR%\..\deps\autohammer
SET TCLSH="C:\Program Files\HammerDB-2.15\bin\tclsh86t.exe"
SET PATH=%TCLSH%;%PATH%

CD %AUTOHAMMER%

REM Kick off autohammer runner
(
    for %%w in (%~1) do (
        for %%u in (%~2) do (
            echo "%SPECDIR%\TPCC_%%w_%%u_RUN"
            START /B tclsh86t autohammer.tcl "%SPECDIR%\TPCC_%%w_%%u_RUN"
            REM ping 192.0.2.2 -n 1 -w 1000 > nul
        )
    )
)

CD %CURRENTDIR%