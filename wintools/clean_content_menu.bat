rem  =============================================================================
rem        FileName: content_menu.bat
rem          Author: Marslo
rem           Email: marslo.jiao@gmail.com
rem         Created: 2016-07-08 11:39:02
rem         Version: 0.0.1
rem      LastChange: 2016-07-08 11:39:02
rem  =============================================================================

rem  Remove Graphic Card information
regsvr32 /u /s igfxpph.dll
reg delete HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxcui /f
reg delete HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM /f
reg delete "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX" /f
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v HotKeysCmds /f
reg delete HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v IgfxTray /f
pause>Nul

rem Folder
reg delete HKEY_CLASSES_ROOT\Directory\shell\Playback /f
reg delete HKEY_CLASSES_ROOT\Directory\shell\PlayList /f
reg delete HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\cloudmusic /f
pause

rem  IoBit
reg delete HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\SmartDefragExtension /f
reg delete HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\SmartDefragExtension /f
reg delete HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\IObitUnstaler /f
reg delete "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Advanced SystemCare" /f
pause

rem  Symantec Corporation
reg delete HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\LDVPMenu /f
reg delete HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\LDVPMenu /f
reg delete HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\LDVPMenu /f
reg delete HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\LDVPMenu /f
pause

rem  Remove Iobit context menu
REG DELETE "HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\SmartDefragExtension" /f
REG DELETE "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\SmartDefragExtension" /f
pause>Nul

rem  Remove Intel Graphics context menu
REG DELETE "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxcui" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM" /f
pause>Nul

rem  Remove qq music context menu
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\QQMusic.1.Play" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\QQMusic.2.Add" /f
pause>Nul

rem  Remove VLC context menu
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\AddToPlaylistVLC" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\PlayWithVLC" /f
pause>Nul
