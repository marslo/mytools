@setlocal
@echo off
set setint=netsh interface set interface
set wlanconn=netsh wlan connect
set wifiname="Wireless Network Connection"
set lanname="Local Area Connection"

IF "%1"=="on" (%setint% %wifiname% Enable)
IF "%1"=="off" (%setint% %wifiname% Disable)
IF "%1"=="lan" (
    IF "%2"=="on" (
      %setint% %lanname% Enable
    ) ELSE (
      %setint% %lanname% Disable
    )
)

IF "%1"=="st" (netsh interface show interface & netsh wlan show interface & net user)
IF "%1"=="show" (netsh wlan show profile & netsh wlan show settings)
IF "%1"=="allint" (netsh wlan show networks)
IF "%1"=="enableall" (
  netsh interface set interface "Local Area Connection" Enable
  netsh interface set interface "Wireless Network Connection" Enable
)
IF "%1"=="showname" (
  FOR /F "tokens=1" %%a in ('netsh interface show interface ^| findstr Local') DO (set lanst=%%a)
  set lanst=!lanst: =!
  echo Local Area Connection: !lanst!

  FOR /F "delims=: tokens=2" %%b in ('netsh wlan show interface ^| findstr SSID ^| findstr /v B') DO (set curwifi=%%b)
  set curwifi=!curwifi: =!
  echo Current Wifi: !curwifi!

  if not "%curwifi%" == "VTAS-Corp" (
    netsh wlan connect "VTAS-Corp"
  )
)

IF "%1"=="mywifi" (
  %setint% %lanname% Disable
  %wlanconn% "VTAS-MyWiFi"
)
IF "%1"=="corp" (%wlanconn% "VTAS-Corp")
IF "%1"=="cu" (%wlanconn% "China Unicom")
IF "%1"=="xx" (%wlanconn% "xxxmmmHUN")



pause
