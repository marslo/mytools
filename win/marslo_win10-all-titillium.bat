echo "Are you sure?"
Pause
Pause

REM  Add fonts
REM  XCOPY "C:\marslo\tools\software\system\font\gisha.ttf" %systemroot%\fonts
REM  XCOPY "C:\marslo\tools\software\system\font\Monaco\MONACO.TTF" %systemroot%\fonts
REM  XCOPY "C:\marslo\tools\software\system\font\ubuntu-font-family-0.80\*.ttf" %systemroot%\fonts
REM  XCOPY "C:\marslo\tools\software\system\font\Monofur\*.ttf" %systemroot%\fonts
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "monofur (TrueType)" /t REG_SZ /d "monof55.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Gisha (TrueType)" /t REG_SZ /d "gisha.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Bold (TrueType)" /t REG_SZ /d  "Ubuntu-B.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Bold Italic (TrueType)" /t REG_SZ /d  "Ubuntu-BI.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Condensed (TrueType)" /t REG_SZ /d  "Ubuntu-C.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Light (TrueType)" /t REG_SZ /d  "Ubuntu-L.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Light Italic (TrueType)" /t REG_SZ /d  "Ubuntu-LI.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Medium (TrueType)" /t REG_SZ /d  "Ubuntu-M.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Medium Italic (TrueType)" /t REG_SZ /d  "Ubuntu-MI.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono Bold (TrueType)" /t REG_SZ /d  "UbuntuMono-B.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono Bold Italic (TrueType)" /t REG_SZ /d  "UbuntuMono-BI.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono (TrueType)" /t REG_SZ /d  "UbuntuMono-R.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono Italic (TrueType)" /t REG_SZ /d  "UbuntuMono-RI.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu (TrueType)" /t REG_SZ /d  "Ubuntu-R.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Italic (TrueType)" /t REG_SZ /d  "Ubuntu-RI.ttf" /f
REM  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Monaco (TrueType)" /t REG_SZ /d  "MONACO.TTF" /f
REM  reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "000" /t REG_SZ /d "monofur" /f

REM  Titillium
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium Light (TrueType)" /t REG_SZ /d "Titillium-Light.otf" /f
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium (TrueType)" /t REG_SZ /d "Titillium-Regular.otf" /f
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium Regular Italic (TrueType)" /t REG_SZ /d "Titillium-RegularItalic.otf" /f
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium Thin (TrueType)" /t REG_SZ /d "Titillium-Thin.otf" /f
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium Semibold (TrueType)" /t REG_SZ /d "Titillium-Semibold.otf" /f
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium Semibold Italic (TrueType)" /t REG_SZ /d "Titillium-SemiboldItalic.otf" /f
REM REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Titillium Light Italic (TrueType)" /t REG_SZ /d "Titillium-LightItalic.otf" /f

REM Disable Chrome history
REG ADD "HKLM\SOFTWARE\Policies\Google\Chrome" /v SavingBrowserHistoryDisabled /t REG_DWORD /d 0x00000001 /reg:64 /f
REG ADD "HKLM\SOFTWARE\Policies\Google\Chrome" /v SavingBrowserHistoryDisabled /t REG_DWORD /d 0x00000001 /f
ATTRIB +R "%LOCALAPPDATA%\Local\Google\Chrome\User Data\Default\History"
ATTRIB +R "%USERPROFILE%\Local Settings\Application Data\Google\Chrome\User Data\Default\History"

REM Black theme
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0x00000000 /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d 0x00000000 /f

REM  Show file extention
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0x00000000 /f

REM Titillium Mapping
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman (TrueType)" /t REG_SZ /d "Titillium-Regular.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman Bold (TrueType)" /t REG_SZ /d "Titillium-Semibold.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman Bold Italic (TrueType)" /t REG_SZ /d "Titillium-SemiboldItalic.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman Italic (TrueType)" /t REG_SZ /d "Titillium-RegularItalic.otf" /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI (TrueType)" /t REG_SZ /d "Titillium-Regular.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Black (TrueType)" /t REG_SZ /d "Titillium-Semibold.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Black Italic (TrueType)" /t REG_SZ /d "Titillium-SemiboldItalic.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Bold (TrueType)" /t REG_SZ /d "Titillium-Semibold.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Bold Italic (TrueType)" /t REG_SZ /d "Titillium-SemiboldItalic.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Italic (TrueType)" /t REG_SZ /d "Titillium-RegularItalic.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Light (TrueType)" /t REG_SZ /d "Titillium-Light.otf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Segoe UI Light Italic (TrueType)" /t REG_SZ /d "Titillium-LightItalic.otf" /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Courier New (TrueType)" /t REG_SZ /d "consola.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Courier New Bold (TrueType)" /t REG_SZ /d "consolab.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Courier New Bold Italic (TrueType)" /t REG_SZ /d "constanz.ttf" /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New Baltic,186" /t REG_SZ /d "Consolas,186" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New CE,238" /t REG_SZ /d "Consolas,238" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New CYR,204" /t REG_SZ /d "Consolas,204" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New Greek,161" /t REG_SZ /d "Consolas,161" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New TUR,162" /t REG_SZ /d "Consolas,162" /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg 2" /t REG_SZ /d "Titillium" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg" /t REG_SZ /d "Titillium" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times" /t REG_SZ /d "Titillium" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman Baltic,186" /t REG_SZ /d "Titillium,186" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman CE,238" /t REG_SZ /d "Titillium,238" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman CYR,204" /t REG_SZ /d "Titillium,204" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman Greek,161" /t REG_SZ /d "Titillium,161" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman TUR,162" /t REG_SZ /d "Titillium,162" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Segoe UI" /t REG_SZ /d "Titillium" /f



REM CLean in win10 Startu Menu
REM Disable "Show recently opened items in Jump List on Start or the taskbar"
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /t REG_DWORD /d 0x00000000 /f
REM Show large taskbar button
REM 0: Large taskbar button; 1: Small taskbar icon
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarSmallIcons" /t REG_DWORD /d 0x00000001 /f

REM  Disable OneDrive
REG ADD "HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 0x00000001 /f

REM  Hide All File Explorer Icons
REM  Disable Show All Folders
REG Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneShowAllFolders /t REG_DWORD /d 0x00000000 /f
REM  OneDrive
REG ADD "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0x00000000 /f
REG ADD "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0x00000000 /f
REM  Libraries
REG ADD "HKCU\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0x00000000 /f

REM  Hide/Show Desktop Icon
REM  Hide Network
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0x00000001 /f
REM  Hide Control Pane
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}" /t REG_DWORD /d 0x00000001 /f
REM  Hide Users Files Desktop
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t REG_DWORD /d 0x00000001 /f
REM  Hide This PC
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0x00000001 /f
REM  Hide Home Group
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{B4FB3F98-C1EA-428d-A78A-D1F5659CBA93}" /t REG_DWORD /d 0x00000001 /f
REM  Show Recycle Bin
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0x00000000 /f
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0x00000000 /f

REM  Quick Access
REM Set Windows Explorer to start on This PC instead of Quick Access
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 0x00000001 /f
REM  Hide Recent Files
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 0x00000000 /f
REM  Hide Frequent Folders
REG ADD "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0x00000000 /f
REM Remove Context Menu
REG DELETE "HKEY_CLASSES_ROOT\Folder\shell\pintohome" /f
REG DELETE "HKLM\SOFTWARE\Classes\Folder\shell\pintohome" /f

REM  Remove usless folders
REM  Remove Desktop From This PC
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /f
REM  Remove Documents From This PC
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /f
REM  Remove Downloads From This PC
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f
REM  Remove Music From This PC
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
REM  Remove Pictures From This PC
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f
REM  Remove Videos From This PC
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" /f
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" /f
REG DELETE "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f

REM Setup IE11
REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Default Download Directory" /t REG_SZ /d "C:\marslo\tools\download" /f
REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\International\Scripts\3" /v "IEPropFontName" /d "Titillium" /f
REM  REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\International\Scripts\3" /v "IEPropFontName" /d "Gill Sans MT" /f
REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\International\Scripts\3" /v "IEFixedFontName" /d "Monaco" /f
REM REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "http://www.google.co.uk" /f
REM REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Start Page Redirect Cache" /t REG_SZ /d "http://www.google.co.uk" /f

REM Hide the search box from taskbar
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0x00000000 /f

REM Set Notepad
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "iPointSize" /t REG_DWORD /d 0x000000dc /f
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "fWrap" /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "lfCharSet" /t REG_DWORD /d 0x00000000 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "lfFaceName" /t REG_SZ /d "Titillium" /f

REM Setup Cursor
REG ADD "HKCU\Control Panel\Cursors" /v  ContactVisualization /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Control Panel\Cursors" /v  GestureVisualization /t REG_DWORD /d 0x0000001f /f
REG ADD "HKCU\Control Panel\Cursors" /v  GestureVisualization /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Control Panel\Cursors" /v  AppStarting /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Working In Background.ani" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Arrow /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Normal Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Crosshair /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Precision Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Hand /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Link Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Help /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Help Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  IBeam /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Text Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  No /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Unavailable.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  NWPen /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Handwriting.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeAll /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Move.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeNESW /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Diagonal Resize 2.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeNS /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Vertical Resize.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeNWSE /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Diagonal Resize 1.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeWE /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Horizontal Resize.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  UpArrow /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Alternate Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Wait /t REG_EXPAND_SZ /d "C:\marslo\tools\software\system\black-lounge\Busy.ani" /f
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" /v BackgroundHistoryPath0 /t REG_SZ /d "C:\marslo\tools\images\mac\Python-List-1920x1080.png" /f
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon" /v MinimizedStateTabletModeOff /t REG_DWORD /d 0x00000001 /f


REM Turn OFF Easy Access Center
REM Mouse Keys
REG ADD "HKCU\Control Panel\Accessibility\MouseKeys" /v "Flags" /t REG_SZ /d "42" /f
REM Filter Keys when SHIFT is pressed for 8 seconds
REM 122 = Off, 126 = On (default) | new: 107 = on, 106 = off
REG ADD "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "106" /f
REM Sticky Keys when SHIFT is pressed 5 times
REM 506 = Off, 510 = On (default) | new: 482 = off, 483 = on | 362 = off & turn off & warning message
REG ADD "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "362" /f
REM Underline keyboard shortcuts and access keys
REG ADD "HKCU\Control Panel\Accessibility\Keyboard Preference" /v "On" /t REG_SZ /d 1 /f

REM Show Hidden files in Explorer
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 0x00000001 /f

REM Show compressed NTFS files in a different color in Explorer
REM 0 = Black (same as non-compressed files); 1 = Blue [default]
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCompColor" /t REG_DWORD /d 0x00000001 /f

REM Expand to current folder in the left panel in Explorer
REM 0 = Don't expand; 1 = Expand
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "NavPaneExpandToCurrentFolder" /t REG_DWORD /d 0x00000001 /f

REM  Taskbar icon combine while taskbar is full
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarGlomLevel" /t REG_DWORD /d 0x00000001 /f

REM  Disable the Small Icon
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarSmallIcons" /t REG_DWORD /d 0x00000000 /f

REM  Set Visual Effects to best apperance
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 0x00000001 /f

REM  Play animations in Windows
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TaskbarAnimations" /v "DefaultApplied" /t REG_DWORD /d 0x00000001 /f

REM  Setup for CMD fonts & windows, properties
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont" /v "0000" /t REG_SZ /d "monofur" /f
REG ADD "HKCU\Console" /v FaceName /t REG_SZ /d "monofur" /f
REG ADD "HKCU\Console" /v FontFamily /t REG_DWORD /d 0x00000036 /f
REG ADD "HKCU\Console" /v FontSize /t REG_DWORD /d 0x001a0000 /f
REG ADD "HKCU\Console" /v FontWeight /t REG_DWORD /d 0x00000190 /f
REG ADD "HKCU\Console" /v WindowAlpha /t REG_DWORD /d 0x000000eb /f
REG ADD "HKCU\Console" /v WindowSize /t REG_DWORD /d 0x00240086 /f
REG ADD "HKCU\Console" /v HistoryBufferSize /t REG_DWORD /d 0x000003e7 /f
REG ADD "HKCU\Console" /v CtrlKeyShortcutsDisabled /t REG_DWORD /d 0x00000000 /f
REG ADD "HKCU\Console" /v ExtendedEditKey /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console" /v QuickEdit /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console" /v ScreenBufferSize /t REG_DWORD /d 0x270f0086 /f
REG ADD "HKCU\Console" /v ScrollScale /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console" /v CurrentPage /t REG_DWORD /d 0x00000000 /f
REG ADD "HKCU\Console" /v CursorSize /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console" /v InsertMode /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console" /v FilterOnPaste /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console" /v LineSelection /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Console\%%SystemRoot%%_System32_cmd.exe" /v "FaceName" /t REG_SZ /d "monofur" /f
REG ADD "HKCU\Console\%%SystemRoot%%_SysWOW64_cmd.exe" /v "FaceName" /t REG_SZ /d "monofur" /f

REM  Setup for cmd auto-complete by tab
REG ADD "HKLM\SOFTWARE\Microsoft\Command Processor" /v "CompletionChar" /t REG_DWORD /d 0x00000009 /f
REG ADD "HKLM\SOFTWARE\Microsoft\Command Processor" /v "PathCompletionChar" /t REG_DWORD /d 0x00000009 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Command Processor" /v "CompletionChar" /t REG_DWORD /d 0x00000009 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Command Processor" /v "PathCompletionChar" /t REG_DWORD /d 0x00000009 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Command Processor" /v "AutoRun" /t REG_SZ /d "@CHCP 65001>nul" /f

REM  Disablea Narrator
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\Narrator.exe" /v "Debugger" /t REG_SZ /d "1" /f

REM Disable Win+G for Game Bar
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d "0x00000000" /f
REG ADD "HKEY_CURRENT_USER\System\GameConfigStore" /v "GameDVR_Enabled" /t REG_DWORD /d "0x00000000" /f

REM Settings > Personalization > Start > Choose which folders appear on Start
DEL "C:\ProgramData\Microsoft\Windows\Start Menu Places\05 - Music.lnk"
DEL "C:\ProgramData\Microsoft\Windows\Start Menu Places\06 - Pictures.lnk"
DEL "C:\ProgramData\Microsoft\Windows\Start Menu Places\07 - Videos.lnk"

REM Remove in library
DEL "%APPDATA%\Microsoft\Windows\Libraries\Documents.library-ms"
DEL "%APPDATA%\Microsoft\Windows\Libraries\Music.library-ms"
DEL "%APPDATA%\Microsoft\Windows\Libraries\Pictures.library-ms"
DEL "%APPDATA%\Microsoft\Windows\Libraries\Videos.library-ms"

REM 3D object
REG DELETE  HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A} /f

REM  Add ctags58 in PATH for VIM
REM  setx /M PATH "%PATH%;C:\marslo\myprogramfiles\vim\bundle\marsloVimOthers\ctags58"
setx CTAGS "C:\marslo\myprogramfiles\vim\bundle\marsloVimOthers\ctags58""
setx /M PATH "%PATH%;%CTAGS%"
setx HOME %USERPROFILE%

REM  Disable the screensaver
REG ADD "HKCU\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaverIsSecure /t REG_SZ /d 0 /f
REG ADD "HKCU\SOFTWARE\Policies\Microsoft\Windows\Control Panel\Desktop" /v ScreenSaveActive /t REG_SZ /d 0 /f

REM  setup command in win-x
REG Add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced /V DontUsePowerShellOnWinX /T REG_DWORD /D 1 /F

REM  Reset and Clear Recent Items
Del /F /Q %APPDATA%\Microsoft\Windows\Recent\*
DEL /F /Q "%APPDATA%\Microsoft\Windows\Recent Items\*"
DEL /F /Q %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*
DEL /F /Q %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*
REG Delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\RunMRU /VA /F
REG Delete HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths /VA /F
XCOPY f01b4d95cf55d32a.automaticDestinations-ms %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*

taskkill /f /im explorer.exe
start explorer.exe

pause

REM pip install --proxy 165.225.96.34:10015 httplib2 urllib3 robotframework selenium robotframework-selenium2library setuptools jenkinsapi pip-review urlopen python-gitlab requests pandas pep8 flake8 autopep8 gittle
REM pip list --outdated
