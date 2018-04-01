#!/usr/bin/env bash
# =============================================================================
# Description: Setup automation environment in MacOS. Using script by: sudo ./osx-setup.sh 
#              Check README.md for manual setup
#              MacOS ONLY.
#      Author: marslo.jiao@gmail.com
#     Created: 2017-11-14 16:49:59
#  LastChange: 2017-11-14 18:31:37
# =============================================================================

exit_on_error() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1. Exiting."
    exit 1
  fi
}

WXPYVER="2.8.12.1"
WXPYNAME="wxPython2.8-osx-unicode-${WXPYVER}-universal-py2.7"
WXPKGNAME="wxPython2.8-osx-unicode-universal-py2.7"

homebrew_install(){
  which brew 2>&1 > /dev/null
  if [ $? -ne 0 ]; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
}


env_pre(){
  sudo easy_install pip
  exit_on_error "ERROR: pip install failed. EXIT."

  defaults write com.apple.versioner.python Prefer-32-Bit -bool yes
  file $(which python)
  homebrew_install
}


lib_install(){
  pip install selenium --user
  sudo pip install -r requirement.txt

  python -c 'import requests'
  exit_on_error "ERROR: requests installed failed. Re-run: sudo pip install -r requirement.txt manually. EXIT."
  python -c 'from appium import webdriver'
  exit_on_error "ERROR: appium installed failed. Re-run: sudo pip install -r requirement.txt manually. EXIT."
  pybot -h
  if [ $? -ne 251 ]; then
    echo "ERROR: pybot installed failed. Re-run: sudo pip install -r requirement.txt manually. EXIT."
    exit 1
  fi
}

ride_setup(){
  curl -O https://nchc.dl.sourceforge.net/project/wxpython/wxPython/${WXPYVER}/${WXPYNAME}.dmg
  hdiutil attach ${WXPYNAME}.dmg

  mkdir temp && tar xvf /Volumes/${WXPYNAME}/${WXPKGNAME}.pkg/Contents/Resources/${WXPKGNAME}.pax.gz -C temp/
  yes | cp -r ./temp/usr/local/lib/* /usr/local/lib/
  ls -al /usr/local/lib/ | grep -i wxpython
  exit_on_error "ERROR: wxPython failed copy to /usr/local/lib. EXIT."
  sudo bash -x /Volumes/${WXPYNAME}/${WXPKGNAME}.pkg/Contents/Resources/postflight
  exit_on_error "ERROR: wxPython failed to execute the postflight. EXIT."

  hdiutil detach /Volumes/wxPython2.8-osx-unicode-2.8.12.1-universal-py2.7
  rm -rf ./temp

  ride.py >/dev/null 2>&1 &
  exit_on_error "ERROR: ride.py cannot be opened. Please reinstall the ${WXPYVER}.dmg manually. EXIT."
  sleep 2
  kill -15 $(ps aux | grep ride | grep -v grep | awk -F' ' '{ print $2 }')
}


main(){
  env_pre
  lib_install
  ride_setup
}

main
