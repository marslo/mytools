rem  =============================================================================
rem        FileName: vpn.bat
rem            Desc: Login Juniper VPN by using Launchy
rem          Author: Marslo
rem           Email: marslo.jiao@gmail.com
rem         Created: 2016-07-08 11:41:15
rem         Version: 0.0.1
rem      LastChange: 2016-07-08 11:41:15
rem  =============================================================================
@SETLOCAL ENABLEDELAYEDEXPANSION

set pwd=<MyPassword>
set user=marslo
set exe="c:\Program Files (x86)\Common Files\Pulse Secure\Integration\pulselauncher.exe"
c:\Program Files (x86)\Common Files\Pulse Secure\Integration\pulselauncher.exe

set cn=vpn-cn.<DomainName>
set emea=vpn-emea.<DomainName>
set in=vpn-in.<DomainName>
set us1=vpn-us1.<DomainName>
set us2=vpn-us2.<DomainName>

if "%1" == "cn" (set url=%cn%)
if "%1" == "emea" (set url=%emea%)
if "%1" == "in" (set url=%in%)
if "%1" == "us1" (set url=%us1%)
if "%1" == "us2" (set url=%us2%)

rem  connection
if "%2" == "on" (%exe% -url %url% -r %url% -u %user% -p %pwd%)
rem  resume
if "%2"=="res" (%exe% -resume -url %url%)
rem  singout
if "%2"=="off" (%exe% -signout -url %url%)
rem  suspend
if "%2"=="sus" (%exe% -suspend -url %url%)

pause>nul
