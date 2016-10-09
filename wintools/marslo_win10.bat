echo "Are you sure?"
Pause
Pause

REM Disable Chrome history
REG ADD "HKLM\SOFTWARE\Policies\Google\Chrome" /v SavingBrowserHistoryDisabled /t REG_DWORD /d "00000001" /reg:64 /f
REG ADD "HKLM\SOFTWARE\Policies\Google\Chrome" /v SavingBrowserHistoryDisabled /t REG_DWORD /d "00000001" /f
ATTRIB +R "C:\Users\310258281\AppData\Local\Google\Chrome\User Data\Default\History"

REM Black theme
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d "00000000" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d "00000000" /f

REM Candara Font
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman (TrueType)" /d "candara.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman Bold (TrueType)" /d "candarab.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman Bold Italic (TrueType)" /d "candaraz.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Times New Roman Italic (TrueType)" /d "candarai.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Courier New (TrueType)" /d "consola.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Courier New Bold (TrueType)" /d "consolab.ttf" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Courier New Bold Italic (TrueType)" /d "constanz.ttf" /f

REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg 2" /d "Candara" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "MS Shell Dlg" /d "Candara" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times" /d "Candara" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman Baltic,186" /d "Candara,186" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman CE,238" /d "Candara,238" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman CYR,204" /d "Candara,204" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman Greek,161" /d "Candara,161" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Times New Roman TUR,162" /d "Candara,162" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New Baltic,186" /d "Consolas,186" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New CE,238" /d "Consolas,238" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New CYR,204" /d "Consolas,204" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New Greek,161" /d "Consolas,161" /f
REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\FontSubstitutes" /v "Courier New TUR,162" /d "Consolas,162" /f

REM CLean in win10 Startu Menu
REM Disable "Show recently opened items in Jump List on Start or the taskbar"
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackDocs" /d 0x00000000 /f

REM  Disable OneDrive
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 0x00000001 /f

REM  Hide File Explorer Icons
rem  Disable Show All Folders
REG Add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NavPaneShowAllFolders /t REG_DWORD /d 0x00000000 /f
REM  OneDrive
REG ADD "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0x00000000 /f
REG ADD "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0x00000000 /f
REM  Network
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWROD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}" /t REG_DWORD /d 0x00000001 /f
REM  Recycle Bin
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWORD /d 0x00000001
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\ClassicStartMenu" /v "{645FF040-5081-101B-9F08-00AA002F954E}" /t REG_DWROD /d 0x00000001
rem  Libraries
REG ADD "HKEY_CURRENT_USER\Software\Classes\CLSID\{031E4825-7B94-4dc3-B131-E946B44C8DD5}" /v "System.IsPinnedToNameSpaceTree" /t REG_DWORD /d 0x00000000 /f

rem  Quick Access
REM Set Windows Explorer to start on This PC instead of Quick Access
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 0x00000001 /f
rem  Hide Recent Files
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowRecent" /t REG_DWORD /d 0x00000000 /f
rem  Hide Frequent Folders
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowFrequent" /t REG_DWORD /d 0x00000000 /f
rem  Remove Context Menu
REG DELETE "-HKEY_CLASSES_ROOT\Folder\shell\pintohome"
REG DELETE "-HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Folder\shell\pintohome"

rem  Remove usless folders
rem  Remove Desktop From This PC
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}" /f
rem  Remove Documents From This PC
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A8CDFF1C-4878-43be-B5FD-F8091C1C60D0}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{d3162b92-9365-467a-956b-92703aca08af}" /f
rem  Remove Downloads From This PC
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{374DE290-123F-4565-9164-39C4925E467B}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{088e3905-0323-4b02-9826-5d99428e115f}" /f
rem  Remove Music From This PC
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{1CF1260C-4DD0-4ebb-811F-33C572699FDE}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}" /f
rem  Remove Pictures From This PC
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{3ADD1653-EB32-4cb0-BBD7-DFA0ABB5ACCA}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{24ad3ad4-a569-4530-98e1-ab02f9417aa8}" /f
rem  Remove Videos From This PC
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{A0953C92-50DC-43bf-BE83-3742FED03C9C}" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}" /f

REM Setup IE11
REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Default Download Directory" /t REG_SZ /d "C:\Marslo\Tools\Download" /f
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\International\Scripts\3" /v "IEPropFontName" /d "Candara" /f
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Internet Explorer\International\Scripts\3" /v "IEFixedFontName" /d "Consolas" /f
REM REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Search Page" /t REG_SZ /d "http://www.google.co.uk" /f
REM REG ADD "HKCU\SOFTWARE\Microsoft\Internet Explorer\Main" /v "Start Page Redirect Cache" /t REG_SZ /d "http://www.google.co.uk" /f

REM Hide the search box from taskbar
REM REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0x00000000 /f

REM Set Notepad
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "iPointSize" /t REG_DWORD /d 0x000000a0 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "fWrap" /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "lfCharSet" /t REG_DWORD /d 0x00000000 /f
REG ADD "HKCU\SOFTWARE\Microsoft\Notepad" /v "lfFaceName" /t REG_SZ /d "Consolas" /f

REM Setup Cursor
REG ADD "HKCU\Control Panel\Cursors" /v  ContactVisualization /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Control Panel\Cursors" /v  GestureVisualization /t REG_DWORD /d 0x0000001f /f
REG ADD "HKCU\Control Panel\Cursors" /v  GestureVisualization /t REG_DWORD /d 0x00000001 /f
REG ADD "HKCU\Control Panel\Cursors" /v  AppStarting /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Working In Background.ani" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Arrow /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Normal Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Crosshair /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Precision Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Hand /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Link Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Help /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Help Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  IBeam /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Text Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  No /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Unavailable.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  NWPen /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Handwriting.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeAll /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Move.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeNESW /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Diagonal Resize 2.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeNS /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Vertical Resize.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeNWSE /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Diagonal Resize 1.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  SizeWE /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Horizontal Resize.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  UpArrow /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Alternate Select.cur" /f
REG ADD "HKCU\Control Panel\Cursors" /v  Wait /t REG_EXPAND_SZ /d "C:\Marslo\Tools\Software\System\black-lounge\Busy.ani" /f
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Wallpapers" /v BackgroundHistoryPath0 /t REG_SZ /v "c:\marslo\tools\images\python-list.png" /f
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Ribbon" /v MinimizedStateTabletModeOff /t REG_DWORD /v 0x00000001 /f



REM Turn OFF Easy Access Center
REM Mouse Keys
REG ADD "HKEY_CURRENT_USER\Control Panel\Accessibility\MouseKeys" /v "Flags" /t REG_SZ /d "42" /f
REM Filter Keys when SHIFT is pressed for 8 seconds
REM 122 = Off, 126 = On (default) | new: 107 = on, 106 = off
REG ADD "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Flags" /t REG_SZ /d "106" /f
REM Sticky Keys when SHIFT is pressed 5 times
REM 506 = Off, 510 = On (default) | new: 482 = off, 483 = on | 362 = off & turn off & warning message
REG ADD "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "362" /f
REM Underline keyboard shortcuts and access keys
REG ADD "HKCU\Control Panel\Accessibility\Keyboard Preference" /v "On" /t REG_SZ /d 1 /f

REM Show Hidden files in Explorer
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t REG_DWORD /d 1 /f

REM Show compressed NTFS files in a different color in Explorer
REM 0 = Black (same as non-compressed files); 1 = Blue [default]
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCompColor" /t REG_DWORD /d 1 /f

REM Expand to current folder in the left panel in Explorer
REM 0 = Don't expand REM; 1 = Expand
REG ADD "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "NavPaneExpandToCurrentFolder" /t REG_DWORD /d 1 /f

rem  Set Visual Effects to best apperance
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t REG_DWORD /d 0x00000001 /f

rem  Play animations in Windows
rem  REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects\TaskbarAnimations" /v "DefaultApplied" /t REG_DWORD /d 0x00000001 /f

rem  Setup for CMD fonts & windows, properties
REG ADD "HKEY_CURRENT_USER\Console" /v FaceName /t REG_SZ /d "Consolas" /f
REG ADD "HKEY_CURRENT_USER\Console" /v FontFamily /t REG_DWORD /d 0x00000036 /f
REG ADD "HKEY_CURRENT_USER\Console" /v FontSize /t REG_DWORD /d 0x00180000 /f
REG ADD "HKEY_CURRENT_USER\Console" /v FontWeight /t REG_DWORD /d 0x00000190 /f
REG ADD "HKEY_CURRENT_USER\Console" /v WindowAlpha /t REG_DWORD /d 0x000000ff /f
REG ADD "HKEY_CURRENT_USER\Console" /v WindowSize /t REG_DWORD /d 0x00240094 /f
REG ADD "HKEY_CURRENT_USER\Console" /v HistoryBufferSize /t REG_DWORD /d 0x000003e7 /f
REG ADD "HKEY_CURRENT_USER\Console" /v CtrlKeyShortcutsDisabled /t REG_DWORD /d 0x00000000 /f
REG ADD "HKEY_CURRENT_USER\Console" /v ExtendedEditKey /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v QuickEdit /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v ScreenBufferSize /t REG_DWORD /d 0x270f0094 /f
REG ADD "HKEY_CURRENT_USER\Console" /v ScrollScale /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v CurrentPage /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v CursorSize /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v InsertMode /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v FilterOnPaste /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v LineSelection /t REG_DWORD /d 0x00000001 /f
REG ADD "HKEY_CURRENT_USER\Console" /v WindowAlpha /t REG_DWORD /d 0x000000eb /f
REG ADD "HKEY_CURRENT_USER\Console\%%SystemRoot%%_System32_cmd.exe" /v "FaceName" /t REG_SZ /d "Consolas" /f
REG ADD "HKEY_CURRENT_USER\Console\%%SystemRoot%%_SysWOW64_cmd.exe" /v "FaceName" /t REG_SZ /d "Consolas" /f

REM Settings > Personalization > Start > Choose which folders appear on Start
DEL "C:\ProgramData\Microsoft\Windows\Start Menu Places\05 - Music.lnk"
DEL "C:\ProgramData\Microsoft\Windows\Start Menu Places\06 - Pictures.lnk"
DEL "C:\ProgramData\Microsoft\Windows\Start Menu Places\07 - Videos.lnk"

REM Remove in library
DEL "%APPDATA%\Microsoft\Windows\Libraries\Documents.library-ms"
DEL "%APPDATA%\Microsoft\Windows\Libraries\Music.library-ms"
DEL "%APPDATA%\Microsoft\Windows\Libraries\Pictures.library-ms"
DEL "%APPDATA%\Microsoft\Windows\Libraries\Videos.library-ms"

rem  Add ctags58 in PATH for VIM
rem  setx /M PATH "%PATH%;C:\Marslo\MyProgramFiles\Vim\bundle\MarsloVimOthers\ctags58"

rem  Reset and Clear Recent Items
DEL /F /Q %APPDATA%\Microsoft\Windows\Recent\*
DEL /F /Q %APPDATA%\Microsoft\Windows\Recent\AutomaticDestinations\*
DEL /F /Q %APPDATA%\Microsoft\Windows\Recent\CustomDestinations\*

rem  taskkill /f /im explorer.exe
rem  start explorer.exe

rem  Add fonts
rem  XCOPY "c:\Marslo\Tools\Software\System\Font\gisha.ttf" %systemroot%\fonts
rem  XCOPY "c:\Marslo\Tools\Software\System\Font\Monaco\MONACO.TTF" %systemroot%\fonts
rem  XCOPY "c:\Marslo\Tools\Software\System\Font\ubuntu-font-family-0.80\*.ttf" %systemroot%\fonts
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Gisha (TrueType)" /t REG_SZ /d "gisha.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Bold (TrueType)" /t REG_SZ /d  "Ubuntu-B.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Bold Italic (TrueType)" /t REG_SZ /d  "Ubuntu-BI.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Condensed (TrueType)" /t REG_SZ /d  "Ubuntu-C.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Light (TrueType)" /t REG_SZ /d  "Ubuntu-L.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Light Italic (TrueType)" /t REG_SZ /d  "Ubuntu-LI.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Medium (TrueType)" /t REG_SZ /d  "Ubuntu-M.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Medium Italic (TrueType)" /t REG_SZ /d  "Ubuntu-MI.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono Bold (TrueType)" /t REG_SZ /d  "UbuntuMono-B.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono Bold Italic (TrueType)" /t REG_SZ /d  "UbuntuMono-BI.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono (TrueType)" /t REG_SZ /d  "UbuntuMono-R.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Mono Italic (TrueType)" /t REG_SZ /d  "UbuntuMono-RI.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu (TrueType)" /t REG_SZ /d  "Ubuntu-R.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Ubuntu Italic (TrueType)" /t REG_SZ /d  "Ubuntu-RI.ttf" /f
rem  REG ADD "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts" /v "Monaco (TrueType)" /t REG_SZ /d  "MONACO.TTF" /f
