@echo off

doskey d=dir $*
doskey ls="C:\marslo\MyProgramFiles\Git\usr\bin\ls.exe"
doskey l="C:\marslo\MyProgramFiles\Git\usr\bin\ls.exe" -l
doskey ll=dir /OD
doskey la=dir /A
doskey c=cls
doskey pwd=cd
doskey ..=cd ..
doskey ...=cd ../..
doskey ....=cd ../../..
doskey :q=exit
doskey :x=exit
doskey :qa=exit
doskey exp=explorer .
doskey openit=explorer.exe $1
doskey ipy=ipython qtconsole --pylab=inline --ConsoleWidget.font_size=12 --IPythonWidget.font_family=Monaco --profile=marslo --colors=linux --style=marslo
doskey pf=pry -f
doskey wlandis=netsh interface set interface name="Wireless Network Connection" admin=disable
doskey wlanen=netsh interface set interface name="Wireless Network Connection" admin=enable
doskey pwd=cd
doskey desk=cd %HOMEPATH%\Desktop
doskey prog=cd %PROGRAMFILES%
doskey up=cd %USERPROFILE%
doskey gh=cd %HOMEPATH%
doskey gr=cd "C:\"
doskey mpr=cd "C:\marslo\MyProgramFiles"
doskey idlelib=cd "C:\marslo\MyProgramFiles\Python27\Lib\idlelib"
doskey jo=cd "C:\marslo\Job"
doskey jco=cd "C:\marslo\Job\Code"
doskey sco=cd "C:\marslo\Study\Code\marslo"
doskey to=cd "C:\marslo\Tools"
doskey gi=cd "C:\marslo\Tools\Git\repo_marslo"
doskey so=cd "C:\marslo\Tools\Software"
doskey cdaccessory=cd "%LOCALAPPDATA\Microsoft\Windows\INetCache\"
doskey cal=gvim %WINDIR%\alias.cmd
doskey alias=type %WINDIR%\alias.cmd
doskey jt=java.exe junit.textui.TestRunner $1
doskey jc=java.exe org.junit.runner.JUnitCore $1
doskey jaw=java -cp .;c:\MyProgrames\junit3.8.1\junit.jar junit.awtui.TestRunner $1
doskey jsw=java -cp .;c:\MyProgrames\junit3.8.1\junit.jar junit.swingui.TestRunner $1
doskey mtty="C:\marslo\MyProgramFiles\cygwin64\bin\mintty.exe" 
doskey subl="C:\marslo\MyProgramFiles\Sublime Text 3\sublime_text.exe" $*
doskey vim="C:\marslo\MyProgramFiles\Vim\vim80\vim.exe" $1
doskey gvim="C:\marslo\MyProgramFiles\Vim\vim80\gvim.exe" $1
doskey addalias=reg add "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "%WINDIR%\alias.cmd"
doskey runbat="C:\Windows\run.bat"
doskey scp=C:\marslo\MyProgramFiles\Git\usr\bin\scp.exe -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "C:\marslo\Tools\Software\System\RemoteConnection\AuthorizedKeys\marslo@devops\marslo@devops" $*
doskey ssh=C:\marslo\MyProgramFiles\Git\usr\bin\ssh.exe -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "C:\marslo\Tools\Software\System\RemoteConnection\AuthorizedKeys\marslo@devops\marslo@devops" $*
