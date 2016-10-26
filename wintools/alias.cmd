@echo off

doskey d=dir $*
doskey ls="C:\Marslo\MyProgramFiles\Git\usr\bin\ls.exe"
doskey l="C:\Marslo\MyProgramFiles\Git\usr\bin\ls.exe" -l
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
doskey mpr=cd "C:\Marslo\MyProgramFiles"
doskey idlelib=cd "C:\Marslo\MyProgramFiles\Python27\Lib\idlelib"
doskey jo=cd "C:\Marslo\Job"
doskey co=cd "C:\Marslo\Job\Code"
doskey to=cd "C:\Marslo\Tools"
doskey gi=cd "C:\Marslo\Tools\Git\repo_marslo"
doskey so=cd "C:\Marslo\Tools\Software"
doskey cal=gvim %WINDIR%\alias.cmd
doskey alias=type %WINDIR%\alias.cmd
doskey jt=java.exe junit.textui.TestRunner $1
doskey jc=java.exe org.junit.runner.JUnitCore $1
doskey jaw=java -cp .;c:\MyProgrames\junit3.8.1\junit.jar junit.awtui.TestRunner $1
doskey jsw=java -cp .;c:\MyProgrames\junit3.8.1\junit.jar junit.swingui.TestRunner $1
doskey mtty="C:\Marslo\MyProgramFiles\cygwin64\bin\mintty.exe" 
doskey subl="C:\Marslo\MyProgramFiles\Sublime Text 3\sublime_text.exe" $*
doskey vim="C:\Marslo\MyProgramFiles\Vim\vim74\vim.exe" $1
doskey gvim="C:\Marslo\MyProgramFiles\Vim\vim74\gvim.exe" $1
doskey addalias=reg add "HKCU\SOFTWARE\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "%WINDIR%\alias.cmd"
doskey runbat="C:\Windows\run.bat"
doskey scp=C:\Marslo\MyProgramFiles\Git\usr\bin\scp.exe -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "c:\Marslo\Tools\Software\System\RemoteConnection\AuthorizedKeys\openssh\marslo@philips" $*
doskey ssh=C:\Marslo\MyProgramFiles\Git\usr\bin\ssh.exe -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "c:\Marslo\Tools\Software\System\RemoteConnection\AuthorizedKeys\openssh\marslo@philips" $*
