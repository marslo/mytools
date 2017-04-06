#!/bin/bash -x

# =============================================================================
#   FileName: updatevim.sh
#       Desc: update gvim.exe and vim.exe
#     Author: Marslo
#      Email: marslo.jiao@gmail.com
#    Created: 2015-09-17 18:20:27
#    Version: 0.0.3
# LastChange: 2017-02-09 17:28:32
#    History:
#             0.0.1 | Marslo | init
#             0.0.2 | Marslo | Build vim win64
#             0.0.3 | Marslo | Add ruby 2.3.0 in
#             0.0.4 | Marslo | Add scp way to upload binary to SourceForge
#             0.0.5 | Marslo | Update for vim 8.0
#             0.0.6 | Marslo | Update Ruby to 2.3.3
# =============================================================================

sour=$HOME/../../Marslo/Tools/Git/vim/src
# dsk=$HOME/Desktop/vim
dsk=/cygdrive/d/Marslo/vim
# dsk=/d/Marslo/im
UPLOAD_FLAG=true
PY_PATH=/cygdrive/c/Marslo/MyProgramFiles/Python27
PY3_PATH=/cygdrive/c/Marslo/MyProgramFiles/Python36
RB_PATH=/cygdrive/c/Marslo/MyProgramFiles/Ruby23-x64
PY_VER=27
PY3_VER=36
RB_VER=23
RB_LONG_VER=2.3.0
# VIM_VER=7.4
VIM_VER=8.0

if [ ! -d "${sour}" ]; then
  echo 'Cannot found vim source. Exit.'
  exit 1
fi

pushd ${sour}
git clean -dfx *
make clean
git checkout -- *


echo '-----------------------------------'
git tag --sort=v:refname | grep v${VIM_VER}'\.' | tail -30
latestver=$(echo "$(git tag --sort=v:refname | grep -i v${VIM_VER}'\.' | tail -1 | awk -F${VIM_VER}. '{print $2}') + 0" | bc)

git status | grep "On branch master"
if [ 0 -eq $? ]; then
  curver=${latestver}
else
  curver=$(git status | grep v${VIM_VER} | awk -F"${VIM_VER}." '{print $2}')
fi

if [ 0 -eq ${curver} ]; then
  curver=${latestver}
fi
nextver=$(echo "${curver} + 1" | bc)

git checkout master
git pull

echo '-----------------------------------'
latestver=$(echo "$(git tag --sort=v:refname | grep -i v${VIM_VER}'\.' | tail -1 | awk -F${VIM_VER}. '{print $2}') + 0" | bc)

if [ ${curver} -eq ${latestver} ]
then
  echo 'No new update. Exit'
  exit 0
fi

echo ${curver}
echo ${nextver}
echo ${latestver}

for i in `seq -w ${nextver} ${latestver}`
do
  ver=${VIM_VER}.`printf "%04d" ${i}`
  targ=${dsk}/${ver}
  echo "----------------------------------- ${ver} --------------------------------------"

  git checkout tags/v${ver}

  make -j 3 -B -f Make_cyg.mak CROSS_COMPILE=x86_64-w64-mingw32- ARCH=x86-64 PYTHON=$PY_PATH DYNAMIC_PYTHON=yes PYTHON_VER=$PY_VER PYTHON3=$PY3_PATH DYNAMIC_PYTHON3=yes PYTHON3_VER=$PY3_VER RUBY=$RB_PATH DYNAMIC_RUBY=yes RUBY_VER=$RB_VER RUBY_VER_LONG=$RB_LONG_VER FEATURES=huge IME=yes GIME=yes MBYTE=yes CSCOPE=yes USERNAME=Marslo.Jiao USERDOMAIN=China GUI=yes > gvim.exe_${ver}.log 2>&1
  make -j 3 -B -f Make_cyg.mak CROSS_COMPILE=x86_64-w64-mingw32- ARCH=x86-64 PYTHON=$PY_PATH DYNAMIC_PYTHON=yes PYTHON_VER=$PY_VER PYTHON3=$PY3_PATH DYNAMIC_PYTHON3=yes PYTHON3_VER=$PY3_VER RUBY=$RB_PATH DYNAMIC_RUBY=yes RUBY_VER=$RB_VER RUBY_VER_LONG=$RB_LONG_VER FEATURES=huge IME=yes GIME=yes MBYTE=yes CSCOPE=yes USERNAME=Marslo.Jiao USERDOMAIN=China GUI=no > vim.exe_${ver}.log 2>&1

  mkdir -p ${targ}
  if [ -f ${sour}/vim.exe ]; then
    cp ${sour}/vim.exe ${targ}
  else
    UPLOAD_FLAG=false
    mv ${sour}/vim.exe_${ver}.log ${targ}/vim.exe_${ver}_failed.log
  fi

  if [ -f ${sour}/gvim.exe ]; then
    cp ${sour}/gvim.exe ${targ}
  else
    UPLOAD_FLAG=false
    mv ${sour}/gvim.exe_${ver}.log ${targ}/gvim.exe_${ver}_failed.log
  fi

 if ${UPLOAD_FLAG}; then
   # scp -i ~/../../Marslo/Tools/Software/System/RemoteConnection/AuthorizedKeys/openssh/Marslo\@philips -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ${targ} marslojiao@frs.sourceforge.net:/home/frs/project/marslos-vim-64/
   scp -i ~/../../Marslo/Tools/Software/System/RemoteConnection/AuthorizedKeys/openssh/Marslo\@philips -o ProxyCommand='corkscrew 42.99.164.34 10015 %h %p' -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -r ${targ} marslojiao@frs.sourceforge.net:/home/frs/project/marslos-vim-64/
 fi
done

popd

# COMMAND: make -j 3 -B -f Make_cyg.mak CROSS_COMPILE=x86_64-w64-mingw32- ARCH=x86-64 PYTHON=/cygdrive/c/Marslo/MyProgramFiles/Python27 DYNAMIC_PYTHON=yes PYTHON_VER=27 PYTHON3=/cygdrive/c/Marslo/MyProgramFiles/Python36 DYNAMIC_PYTHON3=yes PYTHON3_VER=36 RUBY=/cygdrive/c/Marslo/MyProgramFiles/Ruby23-x64 DYNAMIC_RUBY=yes RUBY_VER=23 RUBY_VER_LONG=2.3.0 FEATURES=huge IME=yes GIME=yes MBYTE=yes CSCOPE=yes USERNAME=Marslo.Jiao USERDOMAIN=China GUI=yes
# COMMAND: make -j 3 -B -f Make_cyg.mak CROSS_COMPILE=x86_64-w64-mingw32- ARCH=x86-64 PYTHON=/cygdrive/c/Marslo/MyProgramFiles/Python27 DYNAMIC_PYTHON=yes PYTHON_VER=27 PYTHON3=/cygdrive/c/Marslo/MyProgramFiles/Python36 DYNAMIC_PYTHON3=yes PYTHON3_VER=36 RUBY=/cygdrive/c/Marslo/MyProgramFiles/Ruby23-x64 DYNAMIC_RUBY=yes RUBY_VER=23 RUBY_VER_LONG=2.3.0 FEATURES=huge IME=yes GIME=yes MBYTE=yes CSCOPE=yes USERNAME=Marslo.Jiao USERDOMAIN=China GUI=no
