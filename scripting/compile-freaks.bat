@echo off

cd /d %~dp0

if not exist compiled\freak_fortress_2 mkdir compiled\freak_fortress_2

for %%i in (freaks\*.sp) do (
	echo Compiling %%i...
	spcomp.exe %%i -o compiled\freak_fortress_2\%%~ni.ff2
	echo.
)

pause
