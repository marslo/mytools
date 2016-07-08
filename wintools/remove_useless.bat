@echo off
echo "Close power sleep function (remove hiberfil.sys)"
rem Close power sleep function (remove hiberfil.sys)
powercfg -h off
rem Open power sleep function: powercfg -h on
rem reduce hiberfil.sys size: powercfg -h -size 70

echo "remove useless function"
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\Namespace\{F5270E09-D417-4C5C-93BC-551E5F22ACA6} /f
Pause>Nul

rem  Remove company settings
rem  make wallpaper changeable
REG DELETE "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\ActiveDesktop" /f
REG DELETE "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "Wallpaper" /f
REG DELETE "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "WallpaperStyle" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "Wallpaper" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\System" /v "Wallpaper" /f
Pause>Nul

rem  Remove Welcome notice
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\System" /v "legalnoticecaption" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\System" /v "legalnoticetext" /f
Pause>Nul

rem  Remove secure logon
rem  User Accounts (netplwiz) -> Advanced -> Require users to press Ctrl + Alt + Delete
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DisableCAD" /t REG_DWORD /d "00000001" /f
REG DELETE "HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Winlogon" /v "DisableCAD" /f
REG DELETE "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableCAD" /f
REG DELETE "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableCAD" /f
pause>Nul
