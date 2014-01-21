SET CURRENTDIR=%~dp0

for /D %%i in ("%CURRENTDIR%\..\deps\autohammer\TPCC*") do (
    RD /S /Q %%i
)


for /D %%i in ("%CURRENTDIR%\..\specs\TPCC*") do (
    RD /S /Q %%i
)