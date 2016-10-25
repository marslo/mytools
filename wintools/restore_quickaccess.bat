@echo off

DEL /F /Q %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*
XCOPY f01b4d95cf55d32a.automaticDestinations-ms %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*

pause
