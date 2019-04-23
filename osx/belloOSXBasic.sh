#!/bin/bash
# shellcheck disable=SC1117
# =============================================================================
#    FileName: belloOSXBuilder.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2018-01-18 20:42:27
#  LastChange: 2018-03-28 21:18:21
# =============================================================================

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

SSHDFILE="/etc/ssh/sshd_config"

function installBrew() {
  if ! brew -v > /dev/null 2>&1; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
  brew tap caskroom/versions
  brew cask outdated
  brew tap buo/cask-upgrade
  brew update
  brew cu -a -f
}

function exitOnError() {
  if [ $? -ne 0 ]; then
    echo "ERROR: $1. Exiting."
    exit 1
  fi
}

function setupBrewApps() {
  brew install wget tmux corkscrew tig ifstat jq jshon telnet coreutils tree watch figlet bash-completion@2
  brew install bash gawk less
  brew install gnu-sed --with-default-names
  brew install findutils --with-default-names
  brew install gnu-tar --with-default-names
  brew install gnu-which --with-default-names
  brew install grep --with-default-names
  brew install gnu-indent --with-default-names
  brew cask install google-chrome
  if /usr/local/bin/bash --version; then
    sudo bash -c 'echo "/usr/local/bin/bash" >> /etc/shells'
    chsh -s '/usr/local/bin/bash'
    sudo chsh -s '/usr/local/bin/bash'
  fi
}

function setupSSH() {
  mkdir -p ~/.ssh
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQClCw0e6vrxNWNQehVIeemZ1UMrhVvV9FxVjUkA7AB2SW0kqtrIGxh8tNoPvL0MUm4ga3wgTbITDrVnXeTzh1LE4Wr7j+MRYLbXm6jDp+O5Ow61sBgZjOlX0/7wuDWwfpOafdscmdYKhdatFg6nTDxjiPP44G08N/UWPWuMHxkQNYWj6bt46N8llLOxLJGyTuMjT7TpL6Ubb9WeVo6PYvi+Gl7spHjSHoJ6ZlrcNKxUb7LGh9k1SfXdLeWB079YFCZMrvuVDBYUwwbq6OzrSZnSABdRtR4ylTaHshdQKRmYn3c1/iRybxAwrU5gNYhmikOmWL2Qt0fkINttRswtxKvr marslo@devops" >> ~/.ssh/authorized_keys
  echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7zRA6SKPw4uImacEY0ioLD6jgDnzpZFn8CYaTvXoUf+aio6fwnpG5rMdJf+hN6w7MBIk5tsJGZJxQgNPqJ2gHPTaQDhlAi0R/4vbgk+E1OHK1oXX9DI0qX1RzPFC9gmf9G+40becDxJw7Jp59JQRLsSZg+cq6B4vi/7t70dPBa0UP7zo8CiOjznnf75T674O777rzv4xsjXeWgM42rPctAdUf2YdMLUsv1tOfv2qmpGJDsP/lW9OnVVLYoALQBsWSA+vYtnfgj9N6f0plgxuj8cyee8hJrm2BzW4uqKYScw0vXGUKVYs8TkFUS8COZyoR06Uxkc5dThQDxIUw9jDh slave@devops"  >> ~/.ssh/authorized_keys
  chmod 700 ~/.ssh
  chmod 644 ~/.ssh/authorized_keys
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

function setupEnv() {
  sudo sed -i -e "s:^\($(whoami).*$\):# \1:" /etc/sudoers
  sudo bash -c "echo \"$(whoami)   ALL=(ALL:ALL) NOPASSWD:ALL\" >> /etc/sudoers"

  sudo cp /etc/bashrc{,.org}
  sudo cp ${SSHDFILE}{,.org}
  sudo chflags restricted /usr/local
  sudo chown -R "$(whoami)":admin /usr/local

  mkdir -p ~/Library/LaunchAgents
  sudo chown -R "$(whoami)":wheel /opt
  mkdir -p /opt/{maven,gradle,sonarqube,groovy,java}

  defaults write com.apple.finder FXPreferredViewStyle -string 'Nlsv'
  defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
  defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
  defaults write -g ApplePressAndHoldEnabled -bool false
  defaults write com.apple.desktopservices DSDontWriteNetworkStores true
  defaults write com.apple.finder AppleShowAllFiles TRUE
  defaults write com.apple.finder AppleShowAllFiles YES
  defaults write com.apple.dock mineffect suck
  defaults write com.apple.dock mouse-over-hilite-stack -bool TRUE
  defaults write com.apple.dock static-only -boolean true
  defaults write com.apple.dock showhidden -bool true
  defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2MinimumFontSize -int 18
  defaults write com.apple.LaunchServices LSQuarantine -bool NO
  defaults write com.apple.dashboard mcx-disabled -boolean YES
  killall Dock
  killall Finder

sudo bash -c 'cat >> /etc/bashrc' << EOF

# Setup by script
[ -f /usr/local/bin/screenfetch ] && /usr/local/bin/screenfetch

GRADLE_HOME="/opt/gradle/gradle-3.3"
M2_HOME="/opt/maven/apache-maven-3.3.9"
M2=\$M2_HOME/bin
MAVEN_OPTS="-Xms512m -Xmx1G"
GNUBINHOME="/usr/local/opt/coreutils/libexec/gnubin"
GNUMANHOME="/usr/local/opt/coreutils/libexec/gnuman"
PATH=\$GNUBINHOME:\$M2:\$GRADLE_HOME/bin:\$PATH:"/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
MANPATH=$GNUMANHOME:$MANPATH
CLASSPATH=".:\$JAVA_HOME/lib/tools.jar:\$JAVA_HOME/lib/dt.jar"

export CLASSPATH GRADLE_HOME M2_HOME M2 MAVEN_OPTS PATH MANPATH

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
  plutil i.marslo.addroute.plist
  sudo chown -R root:wheel ~/Library/LaunchAgents/i.marslo.addroute.plist
  sudo launchctl load ~/Library/LaunchAgents/i.marslo.addroute.plist
  launchctl list | grep route

cat > ~/Library/LaunchAgents/i.marslo.updatedb.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>i.marslo.updatedb</string>
	<key>ProgramArguments</key>
	<array>
		<string>sudo</string>
		<string>updatedb</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>StandardErrorPath</key>
	<string>/Users/marslo/.marslo/log/i.marslo.updatedb.log</string>
	<key>StandardOutPath</key>
	<string>/Users/marslo/.marslo/log/i.marslo.updatedb.error.log</string>
	<key>StartInterval</key>
	<integer>300</integer>
</dict>
</plist>
EOF
  plutil i.marslo.updatedb.plist
  sudo chown -R root:wheel ~/Library/LaunchAgents/i.marslo.updatedb.plist
  sudo launchctl load ~/Library/LaunchAgents/i.marslo.updatedb.plist
  launchctl list | grep route
sudo bash -c 'cat >> /etc/hosts ' << EOF
1.2.3.4   domainname
EOF

  sudo scutil --set HostName "devops-${SLAVENAME}"
  sudo scutil --set LocalHostName "devops-${SLAVENAME}"
  sudo scutil --set ComputerName "devops-${SLAVENAME}"
  dscacheutil -flushcache
  sudo shutdown -r now
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

function setupSlaveEnv() {
  [ -z "${SLAVENAME}" ] && exitOnError "Slave Name is empty"
  setupxCode
  installBrew
  setupBrewApps
  setupSSH
  setupSSHD
  setupEnv
}

setupSlaveEnv
