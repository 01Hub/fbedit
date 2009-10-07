echo off
cls
echo Deleting files
echo del Assembly.zip
del Assembly.zip
echo del HighLevel.zip
del HighLevel.zip
echo del Language.zip
del Language.zip
echo del RadASM.zip
del RadASM.zip
echo del RAHelp.zip
del RAHelp.zip
echo del Release.zip
del Release.zip
echo del ..\Release\Addins\*.tmp
del ..\Release\Addins\*.tmp
pause

echo off
cls
echo Lager Assembly.zip
cd ..\Release
"C:\Program Files\WinZip\winzip32.exe" -a -r -p ..\ReleaseMake\Assembly.zip @..\ReleaseMake\ReleaseAssembly.def
cd ..\ReleaseMake
pause

echo off
cls
echo Lager HighLevel.zip
cd ..\Release
"C:\Program Files\WinZip\winzip32.exe" -a -r -p ..\ReleaseMake\HighLevel.zip @..\ReleaseMake\ReleaseHighLevel.def
cd ..\ReleaseMake
pause

echo off
cls
echo Lager Language.zip
cd ..\Release
"C:\Program Files\WinZip\winzip32.exe" -a -r -p ..\ReleaseMake\Language.zip Language\*.*
cd ..\ReleaseMake
pause

echo off
cls
echo Lager RadASM.zip
cd ..\Release
"C:\Program Files\WinZip\winzip32.exe" -a -r -p ..\ReleaseMake\RadASM.zip @..\ReleaseMake\ReleaseRadASM.def
cd ..\ReleaseMake
pause

echo off
cls
echo Lager RAHelp.zip
cd ..\Release
"C:\Program Files\WinZip\winzip32.exe" -a -r -p ..\ReleaseMake\RAHelp.zip Help\RadASM.chm
cd ..\ReleaseMake
pause

echo off
cls
echo Lager Release.zip
cd ..\Release
"C:\Program Files\WinZip\winzip32.exe" -a -r ..\ReleaseMake\Release.zip *.*
cd ..\ReleaseMake
pause
