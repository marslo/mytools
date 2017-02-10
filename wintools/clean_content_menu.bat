regsvr32 /u /s igfxpph.dll
REG DELETE HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxcui /f
REG DELETE HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\XXX Groove GFS Context Menu Handler XXX" /f
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v HotKeysCmds /f
REG DELETE HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Run /v IgfxTray /f

REM Remove NAVIDA Control Panel
REG DELETE HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\NvCplDesktopContext /f
REG DELETE HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\SmartDefragExtension /f
REG DELETE HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\IObitUnstaler /f
REG DELETE HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\SmartDefragExtension /f
REG DELETE "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Advanced SystemCare" /f
REG DELETE HKEY_CLASSES_ROOT\Directory\shell\Playback /f
REG DELETE HKEY_CLASSES_ROOT\Directory\shell\PlayList /f
REG DELETE HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\cloudmusic /f

rem  IoBit
REG DELETE HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\SmartDefragExtension /f
REG DELETE HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\SmartDefragExtension /f

rem  Symantec Corporation
REG DELETE HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\LDVPMenu /f
REG DELETE HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\LDVPMenu /f
REG DELETE HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\LDVPMenu /f
REG DELETE HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\LDVPMenu /f

rem  Remove Iobit context menu
REG DELETE "HKEY_CLASSES_ROOT\Folder\ShellEx\ContextMenuHandlers\SmartDefragExtension" /f
REG DELETE "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\SmartDefragExtension" /f

rem  Remove Intel Graphics context menu
REG DELETE "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxcui" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\igfxDTCM" /f

rem  Remove qq music context menu
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\QQMusic.1.Play" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\QQMusic.2.Add" /f

rem  Remove VLC context menu
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\AddToPlaylistVLC" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shell\PlayWithVLC" /f

rem  Remove Pin to Quick Access
REG DELETE "HKEY_CLASSES_ROOT\Folder\shell\pintohome" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Classes\Folder\shell\pintohome" /f

rem  Beyond Compare
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Advanced SystemCare" /f
REG DELETE "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\CirrusShellEx" /f
REG DELETE "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\CirrusShellEx" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\CirrusShellEx" /f

rem  IOBit
REG DELETE "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\IObitUnstaler" /f
REG DELETE "HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Advanced SystemCare" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\IObitUnstaler" /f

rem  McAfee
REG DELETE "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\VirusScan" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\VirusScan" /f
REG DELETE "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\VirusScan" /f

rem  Restore Previous Versions
REG DELETE "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
REG DELETE "HKEY_CLASSES_ROOT\CLSID\{450D8FBA-AD25-11D0-98A8-0800361B1103}\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f
REG DELETE "HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\{596AB062-B4D2-4215-9F74-E9109B0A8153}" /f

rem Share with
REG DELETE "HKEY_CLASSES_ROOT\*\shellex\ContextMenuHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\Background\shellex\ContextMenuHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\ContextMenuHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\CopyHookHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\Directory\shellex\PropertySheetHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\Drive\shellex\ContextMenuHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\Drive\shellex\PropertySheetHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\LibraryFolder\background\shellex\ContextMenuHandlers\Sharing" /f
REG DELETE "HKEY_CLASSES_ROOT\UserLibraryFolder\shellex\ContextMenuHandlers\Sharing" /f

rem  BitLockerDrive
REG DELETE "HKEY_CLASSES_ROOT\Drive\shell\encrypt-bde" /f
REG DELETE "HKEY_CLASSES_ROOT\Drive\shell\encrypt-bde-elev" /f

rem  QQ
REG DELETE "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\QQShellExt" /f
REG DELETE "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\QQShellExt" /f
REG DELETE "HKEY_CLASSES_ROOT\lnkfile\shellex\ContextMenuHandlers\QQShellExt" /f
REG DELETE "HKEY_CLASSES_ROOT\AllFilesystemObjects\shellex\ContextMenuHandlers\QQShellExt64" /f
REG DELETE "HKEY_CLASSES_ROOT\Folder\shellex\ContextMenuHandlers\QQShellExt64" /f
REG DELETE "HKEY_CLASSES_ROOT\lnkfile\shellex\ContextMenuHandlers\QQShellExt64" /f
