Copy ..\Addins\*.dll Sim52\Addins
Copy ..\Sfr\*.sfr Sim52\Sfr
Copy ..\Sim52.exe Sim52
Copy ..\Sim52.ini Sim52
Pause
del ..\Sim52.zip
"C:\Program Files\WinZip\winzip32.exe" -a -r -ex ..\Sim52.zip Sim52\*.*
Pause
