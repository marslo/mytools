#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2216,SC2115
# =============================================================================
#    FileName: belloOSXAutomation.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2017-11-14 16:49:59
#  LastChange: 2018-02-28 16:57:34
# =============================================================================
# USAGE:
#     please repace the SONARURL and ARTIFACTORYHOST to your own situation

while getopts "t:" opt; do
  case $opt in
    t)
      SLAVENAME="$OPTARG"
      ;;
    \?)
      echo "USAGE: $0 -t [SLAVENAME]"
      exit 1
      ;;
  esac
done

WXPYVER="2.8.12.1"
WXPYNAME="wxPython2.8-osx-unicode-${WXPYVER}-universal-py2.7"
WXPKGNAME="wxPython2.8-osx-unicode-universal-py2.7"
SONARURL="http://my.sonar.com:9000"
SONARTOEKEN="SONARTOEKEN"
ARTIFACTORYHOST="my.company.com/artifactory"
ARTIFACTORYURL="http://${ARTIFACTORYHOST}/artifactory"
ARTIPIPREPO="${ARTIFACTORYURL}/api/pypi/pypi-dev/simple"
PIPOPT="--trusted-host ${ARTIFACTORYHOST} --index-url ${ARTIPIPREPO}"
WEBDRIVERAGENTDIR="/usr/local/lib/node_modules/appium/node_modules/appium-xcuitest-driver/WebDriverAgent"
NPMVER="6.11.0"
TIMESTAMP=$(date +%Y%m%d%H%M%S)

JAVADIR="/opt/java"
GRADLEDIR="/opt/gradle"
AUTOMATIONDIR="/opt/automation"
NDIR="/opt/n"

function exitOnError() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1. Exiting."
    exit 1
  fi
}

function setupBasicEnv() {
sudo sed -i -e "s:^\\($(whoami).*$\\):# \\1:" /etc/sudoers
sudo bash -c "echo \"$(whoami)   ALL = (ALL) NOPASSWD:ALL\" >> /etc/sudoers"
sudo mkdir -p /opt/{automation,n}
mkdir -p ~/.ssh
sudo chown -R "$(whoami)":admin /usr/local
sudo chown -R "$(whoami)":wheel /opt

sudo scutil --set HostName "devops-${SLAVENAME}"
sudo scutil --set LocalHostName "devops-${SLAVENAME}"
sudo scutil --set ComputerName "devops-${SLAVENAME}"
dscacheutil -flushcache

sudo bash -c 'cat >> /etc/bashrc' << EOF
GNUBINHOME="/usr/local/opt/coreutils/libexec/gnubin"
GNUMANHOME="/usr/local/opt/coreutils/libexec/gnuman"
PATH=\$GNUBINHOME:\$PATH
MANPATH=\$GNUMANHOME:\$MANPATH
NODE_PATH=/usr/local/lib/node_modules:\$NODE_PATH

export GNUBINHOME GNUMANHOME PATH MANPATH NODE_PATH
[ -f /usr/local/bin/screenfetch ] && /usr/local/bin/screenfetch

export LANG=en_US.UTF-8
export LANGUAGE=\$LANG
export LC_COLLATE=\$LANG
export LC_CTYPE=\$LANG
export LC_MESSAGES=\$LANG
export LC_MONETARY=\$LANG
export LC_NUMERIC=\$LANG
export LC_TIME=\$LANG
export LC_ALL=\$LANG

alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias -- +="pushd ."
alias -- -="popd"
alias ws="cd ~/workspace"
alias la="ls -Al"
alias wa="which -a"
EOF

cat > ~/.inputrc << EOF
set convert-meta on
set completion-ignore-case on
set show-all-if-ambiguous on
set show-all-if-unmodified on
set mark-symlinked-directories on
set print-completions-horizontally on
EOF

sudo bash -c 'cat >> /usr/local/bin/addr' << EOF
#!/bin/bash
#
# =============================================================================
#    FileName: add_route.sh
#      Author: marslo.jiao@gmail.com
#        Desc: Setup dual-network card for both public and PGN network
#     Created: 2017-11-11 10:17:22
#  LastChange: 2018-01-23 20:08:13
# =============================================================================

INTRANETROUTE="4.3.2.1"

sudo route -nv add -host 1.2.3.4     ${INTRANETROUTE}
sudo route -nv add -net 192.168/16        ${INTRANETROUTE}
EOF

cat > ~/Library/LaunchAgents/i.marslo.addroute.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>i.marslo.addroute</string>
        <key>WorkingDirectory</key>
        <string>/Users/devops</string>
        <key>ProgramArguments</key>
        <array>
            <string>/usr/local/bin/addr</string>
        </array>
        <key>EnableGlobbing</key>
        <true/>
        <key>RunAtLoad</key>
        <true/>
        <key>KeepAlive</key>
        <true/>
    </dict>
</plist>
EOF

plutil ~/Library/LaunchAgents/i.marslo.addroute.plist
sudo chown -R root:wheel ~/Library/LaunchAgents/i.marslo.addroute.plist
sudo launchctl load ~/Library/LaunchAgents/i.marslo.addroute.plist
sudo launchctl list | grep route

sudo bash -c 'cat >> /etc/hosts ' << EOF
1.2.3.4 domainname
EOF

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClCw0e6vrxNWNQehVIeemZ1UMrhVvV9FxVjUkA7AB2SW0kqtrIGxh8tNoPvL0MUm4ga3wgTbITDrVnXeTzh1LE4Wr7j+MRYLbXm6jDp+O5Ow61sBgZjOlX0/7wuDWwfpOafdscmdYKhdatFg6nTDxjiPP44G08N/UWPWuMHxkQNYWj6bt46N8llLOxLJGyTuMjT7TpL6Ubb9WeVo6PYvi+Gl7spHjSHoJ6ZlrcNKxUb7LGh9k1SfXdLeWB079YFCZMrvuVDBYUwwbq6OzrSZnSABdRtR4ylTaHshdQKRmYn3c1/iRybxAwrU5gNYhmikOmWL2Qt0fkINttRswtxKvr marslo@devops" >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 644 ~/.ssh/authorized_keys

bash -x ./belloMarsloDefaults.sh
# sudo shutdown -r now

}

function setupxCode() {
  xcode-select --install
  sudo xcodebuild -license accept
  # for pkgs
  for pkg in /Applications/Xcode.app/Contents/Resources/Packages/*.pkg; do
    sudo installer -pkg "$pkg" -target /;
  done
  # for componets
  /Applications/Xcode.app/Contents/MacOS/Xcode -installComponents
  # enable developer mode
  sudo sudo DevToolsSecurity -enable
}

function installBrew() {
  if ! brew -v > /dev/null 2>&1; then
    /usr/bin/ruby \
      -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" \
     < /dev/null
  fi
  brew tap caskroom/versions
  brew update
}

function setupBrewApps() {
  brew install wget tmux corkscrew tig bash-completion ifstat jq jshon telnet coreutils tree watch figlet cmake screenfetch

  brew install bash gawk less
  brew install gnu-sed --with-default-names
  brew install findutils --with-default-names
  brew install gnu-tar --with-default-names
  brew install gnu-which --with-default-names
  brew install grep --with-default-names
  brew install gnu-indent --with-default-names

  brew cask install google-chrome
  sudo bash -c 'echo "/usr/local/bin/bash" >> /etc/shells'
  chsh -s '/usr/local/bin/bash'
  sudo chsh -s '/usr/local/bin/bash'

  brew list | grep carthage >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    brew uninstall carthage
  fi
  brew install carthage
  brew unlink carthage
  brew link --overwrite carthage

  brew install --HEAD libimobiledevice
  echo /usr/local/opt/libxml2/lib/python2.7/site-packages >> /usr/local/lib/python2.7/site-packages/libxml2.pth
  [ ! -d "$HOME/Library/Python/2.7/lib/python/site-packages" ] && mkdir -p "$HOME/Library/Python/2.7/lib/python/site-packages"
  echo 'import site; site.addsitedir("/usr/local/lib/python2.7/site-packages")' >> "$HOME/Library/Python/2.7/lib/python/site-packages/homebrew.pth"
  brew unlink libimobiledevice
  brew link --overwrite libimobiledevice
  brew install --HEAD ideviceinstaller
  brew unlink ideviceinstaller
  brew link --overwrite ideviceinstaller

  brew unlink xz
  sudo gem install cupertino
  brew link xz
}

function setupSSHD() {
  sudo bash -c 'sed -i -e "s:^\(UsePAM.*$\):# \1:" ${SSHDFILE}'
  sudo bash -c 'sed -i -e "s:^\(PermitRootLogin.*$\):# \1:" ${SSHDFILE}'
  sudo bash -c 'sed -i -e "s:^\(ChallengeResponseAuthentication.*$\):# \1:" ${SSHDFILE}'
  sudo bash -c 'sed -i -e "s:^\(PasswordAuthentication.*$\):# \1:" ${SSHDFILE}'

sudo bash -c "cat >> ${SSHDFILE}" << EOF

# Add my marslo
PermitRootLogin no
UsePAM no
ChallengeResponseAuthentication no
PasswordAuthentication no
PrintMotd yes
Banner /etc/ssh/server.banner
EOF

  set +o histexpand
  sudo bash -c "figlet -f big \"Jenkins ${SLAVENAME} !\" > /etc/ssh/server.banner"
  set -H

  sudo launchctl stop com.openssh.ssh-agent; sudo launchctl start com.openssh.ssh-agent;
}

function npmInstall() {
  git clone https://github.com/tj/n ${NDIR}
  cd ${NDIR} || exit
  make install
  sudo chown -R "$(whoami)":wheel /usr/local/n
}

function javaInstall() {
  curl ${ARTIFACTORYURL}/devops/iOS/java/jdk-8u161-macosx-x64.dmg --create-dirs -o ${JAVADIR}/jdk-8u161-macosx-x64.dmg
  diskutil list
  hdiutil attach ${JAVADIR}/jdk-8u161-macosx-x64.dmg
  sudo installer -verbose -pkg "/Volumes/JDK 8 Update 161/JDK 8 Update 161.pkg" -target /
  hdiutil unmount "/Volumes/JDK 8 Update 161" -force
  hdiutil detach "/Volumes/JDK 8 Update 161"
  diskutil list
  /usr/libexec/java_home -v 1.8.0.161 --exec javac -version
  which -a javac
  which -a java
  java -version
  javac -version
}

function npmSetup() {
  [ -f "$HOME/.npmrc" ] && mv $HOME/.npmrc{,.bak.${TIMESTAMP}}

  cat > $HOME/.npmrc << EOF
registry=${ARTIFACTORYURL}/api/npm/npm-snapshot/
@appium=${ARTIFACTORYURL}/api/npm/npm-snapshot
@appium-chromedriver=${ARTIFACTORYURL}/api/npm/npm-snapshot
chromedriver_cdnurl=${ARTIFACTORYURL}/mirror-chromedriver
sass_binary_site=${ARTIFACTORYURL}/mirror-node-sass
phantomjs_cdnurl=${ARTIFACTORYURL}/mirror-phantomjs
nvm_nodejs_org_mirror=${ARTIFACTORYURL}/mirror-nodejs
nvm_iojs_org_mirror=${ARTIFACTORYURL}/mirror-iojs
nvm_npm_mirror=${ARTIFACTORYURL}/mirror-npm
# echo "progress=falseg
EOF

  sudo chown -R "$(whoami)":admin /usr/local

  n ${NPMVER}
  npm --version
  node --version

  npm i -g npm@latest --verbose
  npm i -g appium@1.6.5 --verbose --chromedriver_cdnurl=${ARTIFACTORYURL}/mirror-chromedriver
  npm i -g wd --verbose
  npm i -g ios-deploy --unsafe-perm=true --verbose
  npm i -g gnomon --verbose
}

function gradleInstall() {
  wget ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.5-all.zip -P ${GRADLEDIR}
  curl ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.3-all.zip --create-dirs -o ${GRADLEDIR}/gradle-3.3-all.zip
  unzip ${GRADLEDIR}/gradle-3.3-all.zip -d ${GRADLEDIR}
  curl ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.5-all.zip --create-dirs -o ${GRADLEDIR}/gradle-3.5-all.zip
  unzip ${GRADLEDIR}/gradle-3.5-all.zip -d ${GRADLEDIR}
}

function gradleSetup() {
  [ -f ~/.gradle/gradle.properties ] && mv ~/.gradle/gradle.properties{,.bak.${TIMESTAMP}} || mkdir -p ~/.gradle
  cat > ~/.gradle/gradle.properties << EOF
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx2048M
artifactory_contextUrl=${ARTIFACTORYURL}
systemProp.sonar.host.url=${SONARURL}
systemProp.sonar.login=${SONARTOEKEN}
EOF
}

function setupPypi(){
[ ! -d ~/Library/Application\ Support/pip ] && mkdir -p ~/Library/Application\ Support/pip
[ -f ~/.pip/pip.conf ] && mv ~/.pip/pip.conf{,.bak.${TIMESTAMP}}
[ ! -d ~/.pip ] && mkdir ~/.pip

cat > ~/.pip/pip.conf << EOF
[global]
index-url = ${ARTIPIPREPO}
extra-index-url = ${ARTIPIPREPO}
[list]
format = columns
[install]
trusted-host=${ARTIFACTORYHOST}
EOF

  defaults write com.apple.versioner.python Prefer-32-Bit -bool yes
  # sudo easy_install pip
  curl ${ARTIFACTORYURL}/devops/automation/get-pip.py --create-dirs -o ${AUTOMATIONDIR}/get-pip.py
  sudo -H python ${AUTOMATIONDIR}/get-pip.py ${PIPOPT}
  exitOnError "ERROR: pip install failed. EXIT."

  sudo chown "$(whoami)":admin /usr/local/bin/pip*
  sudo chown "$(whoami)":admin /usr/local/bin/wheel
  file "$(which python)"
  file "$(which pip)"
}

function pipLibInstallation(){
cat > ${AUTOMATIONDIR}/requirement.txt <<EOF
--index-url ${ARTIPIPREPO}
Appium-Python-Client==0.25
requests==2.18.4
robotframework==3.0.2
robotframework-appiumlibrary==1.4.6
robotframework-ride==1.5.2.1
xlrd==1.0.0
Pygments==2.2.0
pyserial==3.4
numpy==1.14.0
matplotlib==2.1.2
beautifulsoup4==4.6.0
pillow==5.0.0
nose==1.3.7
EOF

  sudo -H pip install selenium ${PIPOPT}
  sudo -H pip install -r ${AUTOMATIONDIR}/requirement.txt --trusted-host ${ARTIFACTORYHOST}

  python -c 'import requests'
  exitOnError "ERROR: requests installed failed. Re-run: sudo pip install -r requirement.txt manually. EXIT."
  python -c 'from appium import webdriver'
  exitOnError "ERROR: appium installed failed. Re-run: sudo pip install -r requirement.txt manually. EXIT."
  pybot -h
  if [ $? -ne 251 ]; then
    echo "ERROR: pybot installed failed. Re-run: sudo pip install -r requirement.txt manually. EXIT."
    exit 1
  fi
}

function setupRide(){
  curl ${ARTIFACTORYURL}/devops/automation/wxPython2.8-osx-unicode-2.8.12.1-universal-py2.7.dmg --create-dirs -o ${AUTOMATIONDIR}/${WXPYNAME}.dmg
  hdiutil attach ${AUTOMATIONDIR}/${WXPYNAME}.dmg

  tar xvf /Volumes/${WXPYNAME}/${WXPKGNAME}.pkg/Contents/Resources/${WXPKGNAME}.pax.gz -C ${AUTOMATIONDIR}/
  yes | cp -r ${AUTOMATIONDIR}/usr/local/lib/* /usr/local/lib/
  ls -al /usr/local/lib/*wxPython*
  exitOnError "ERROR: wxPython failed copy to /usr/local/lib. EXIT."
  sudo bash -x /Volumes/${WXPYNAME}/${WXPKGNAME}.pkg/Contents/Resources/postflight
  exitOnError "ERROR: wxPython failed to execute the postflight. EXIT."

  hdiutil eject /Volumes/wxPython2.8-osx-unicode-2.8.12.1-universal-py2.7
  rm -rf "${AUTOMATIONDIR}/usr"

  ride.py >/dev/null 2>&1 &
  exitOnError "ERROR: ride.py cannot be opened. Please reinstall the ${WXPYVER}.dmg manually. EXIT."
  sleep 2
  kill -15 "$(pgrep -f ride.py)"
}

function setupWebDriverAgent() {
  [ -d "${WEBDRIVERAGENTDIR}" ] && exitOnError "cannot find WebDriverAgent in appium/node_moduel"
  mkdir -p ${WEBDRIVERAGENTDIR}/Resources/WebDriverAgent.bundle

  pushd .
  cd ${WEBDRIVERAGENTDIR}
  bash -x Scripts/bootstrap.sh
  exitOnError "failed in execution Scripts/bootstraps.sh in WebDriverAgent"
  popd
}

function basicSetup() {
  [ -z "${SLAVENAME}" ] && exitOnError "Slave Name is empty"
  setupBasicEnv
  setupxCode
  installBrew
  setupBrewApps
  setupSSHD
  npmInstall
  sudo shutdown -r now
}

function automationEnvSetup(){
  javaInstall
  npmSetup
  gradleInstall
  gradleSetup
  setupPypi
  pipLibInstallation
  setupRide
  setupWebDriverAgent
}

basicSetup
automationEnvSetup
