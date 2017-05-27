@setlocal
@echo off

rem  =============================================================================
rem  #     FileName: mcd.bat
rem  #       Author: Marslo
rem  #        Email: marslo.jiao@gmail.com
rem  #      Created: 2017-05-27 17:02:14
rem  #   LastChange: 2017-05-27 17:32:34
rem  =============================================================================

set mbash=C:\Marslo\MyProgramFiles\cygwin64\bin\mintty.exe -i C:\Marslo\MyProgramFiles\cygwin64\Cygwin-Terminal.ico /bin/bash -lc
set mhome=$HOME/../../Marslo
set jco=%mhome%/Job/Code
set sco=%mhome%/Study/Code
set tool=%mhome%/Tools


IF "%1"=="mj" (set localtion=%mhome%)
IF "%1"=="home" (set localtion=$HOME)
IF "%1"=="sco" (set localtion=%sco%)
IF "%1"=="jco" (set localtion=%jco%)
IF "%1"=="devops" (set localtion=%jco%/DevOps)
IF "%1"=="mgi" (set localtion=%tool%/Git/repo_marslo)

%mbash% 'export STARTIN=%localtion%; /bin/bash'
