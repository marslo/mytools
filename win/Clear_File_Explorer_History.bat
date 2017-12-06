:: Created by: Shawn Brink
:: http://www.tenforums.com
:: Tutorial: http://www.tenforums.com/tutorials/6712-file-explorer-history-clear-windows-10-a.html


Del /F /Q %APPDATA%\Microsoft\Windows\Recent\*

Del /F /Q %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*

Del /F /Q %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*

REG Delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /VA /F

REG Delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths /VA /F 

