@setlocal
@echo off

rem  =============================================================================
rem       FileName: wifi.bat
rem         Author: Marslo
rem          Email: marslo.jiao@gmail.com
rem        Created: 2016-10-26 23:42:56
rem        Version: 0.0.1
rem  =============================================================================

set setint=netsh interface set interface
set wlanconn=netsh wlan connect

for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
  IF "%version%" == "10.0" (
    set wifiname=Wi-Fi
    set lanname=Ethernet
  ) ELSE (
    set wifiname="Wireless Network Connection"
    set lanname="Local Area Connection"
  )

IF "%1"=="on" (
  net file 1>nul 2>nul && goto :runon || powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c %~fnx0 %*'"
  goto :eof
  :runon
  netsh int set int Wi-Fi Enable
  pause
  )

IF "%1"=="off" (
  net file 1>nul 2>nul && goto :runoff || powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c %~fnx0 %*'"
  goto :eof
  :runoff
  netsh int set int Wi-Fi Disable
  pause
  )

IF "%1"=="lan" (
  IF "%2"=="off" (
    net file 1>nul 2>nul && goto :runlanoff || powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c %~fnx0 %*'"
    goto :eof
    :runlanoff
    %setint% %lanname% Disable
  ) ELSE (
    IF "%2"=="on" (
      net file 1>nul 2>nul && goto :runlanon || powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c %~fnx0 %*'"
      goto :eof
      :runlanon
      %setint% %lanname% Enable
      )
  )
  pause
)

IF "%1"=="enableall" (
  net file 1>nul 2>nul && goto :runall || powershell -ex unrestricted -Command "Start-Process -Verb RunAs -FilePath '%comspec%' -ArgumentList '/c %~fnx0 %*'"
  goto :eof
  :runall
  netsh interface set interface %lanname% Enable
  netsh interface set interface %wifiname% Enable
  %wlanconn% "WLAN-PHI"
  echo Enable both Wlan and Lan, and connected to WLAN-PHI
  pause
)

IF "%1"=="showname" (
  for /f "tokens=4" %%i in ('netsh interface show interface ^| findstr Ethernet ') do echo Local Area Connection: %%i
  for /f "delims=: tokens=2" %%j in ('netsh wlan show interface ^| findstr SSID ^| findstr /v B') DO (echo current wifi: %%j)
  pause
)

IF "%1"=="help" (
  echo NAME:
  echo    wifi.bat - Control or show information for both WLAN and LAN in Launchy.
  echo=
  echo USAGE:
  echo    launchy:    wifi ^<tab^> [ on ^| off ^| st ^| show ^| allint ^| enableall ^| phi ^| pub ^| lan on ^| lan off ^| lanwin ^| lanset ^| help ^| usage ^| whodidit ]
  echo    cmd:        wifi.bat [ on ^| off ^| st ^| show ^| allint ^| enableall ^| phi ^| pub ^| lan on ^| lan off ^| lanwin ^| lanset ^| help ^| usage ^| whodidit ]
  echo=
  echo Description:
  echo    on:         enable wlan [current user need elevated permission]
  echo    off:        disable wlan [current user need elevated permission]
  echo    st:         show wlan and lan status
  echo    show:       show wlan status
  echo    allint:     show all available wifi
  echo    phi:        connect to "WLAN-PHI"
  echo    pub:        connect to "WLAN-PUB"
  echo    enableall:  Enable WLAN and LAN interface and connect to WLAN-PHI
  echo    lan on:     enable Local Area Connection [current user need elevated permission]
  echo    lan off:    disable Local Area Connection [current user need elevated permission]
  echo=
  echo EXAMPLE:
  echo    wifi ^<tab^> pub ^<enter^>        :  connect WLAN-PUB
  echo    wifi ^<tab^> phi ^<enter^>        :  connect wlan-pub
  echo    wifi ^<tab^> enableall ^<enter^>  :  Enable WLAN and LAN interface, and connect to WLAN-PHI automatically
  echo    wifi ^<tab^> lanset ^<enter^>     :  Open Internet Propertites -^> Connections ^(For setup proxy^)
  echo    wifi ^<tab^> lanwin ^<enter^>     :  Open Network Connections in Control Pannel ^(Control or check Network Interface status^)
  echo=
  echo AUTHOR:
  echo    MarsloJiao@China ^(marslo.jiao@gmail.com^), Repo: https://github.com/Marslo/mytools/blob/master/wintools/wifi.bat
  echo    Find more details:
  echo        cmd: ^> wifi.bat whodidit  OR  launchy: wifi ^<tab^> whodidit ^<enter^>
  echo=
  pause
 )

 IF "%1"=="usage" (
  echo=
  echo How to use this script in Launchy:
  echo    Launchy Options -^> Plugins -^> Runner -^> +
  echo      Name: ^<whatever you want ^> ^(wifi for example^)
  echo      Program:  ^<Full path of wifi.bat^>
  echo      Arguments: $$
  echo    OK -^> Catalog -^> Rescan Catalog
  echo=
  pause
 )

IF "%1"=="st" (netsh interface show interface & netsh wlan show interface & net user & pause)
IF "%1"=="show" (netsh wlan show profile & netsh wlan show settings & pause)
IF "%1"=="allint" (netsh wlan show networks & pause)
IF "%1"=="whichwifi" (netsh wlan show interface | findstr Profile | findstr /v mode & pause)
IF "%1"=="phi" (%wlanconn% "WLAN-PHI" & pause )
IF "%1"=="pub" (%wlanconn% "WLAN-PUB" & pause)

IF "%1"=="lanwin" (C:\Windows\System32\rundll32.exe shell32.dll,Control_RunDLL ncpa.cpl)
IF "%1"=="lanset" (C:\Windows\System32\rundll32.exe shell32.dll,Control_RunDLL inetcpl.cpl,,4)

IF "%1"=="whodidit" (echo Awesome Marslo! & echo= & echo Agree please close the window, or press any key, :^). And well done, Marsl! & echo= & pause)

endlocal
