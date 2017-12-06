echo "Close power sleep function (remove hiberfil.sys)"
rem Close power sleep function (remove hiberfil.sys)
powercfg -h off
rem Open power sleep function: powercfg -h on
rem reduce hiberfil.sys size: powercfg -h -size 70

echo "remove useless function"
reg delete HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\Namespace\{F5270E09-D417-4C5C-93BC-551E5F22ACA6} /f
pause
