#!/bin/bash

sysctl user.cs_path
sudo sysctl -w user.cs_path=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
sudo launchctl config user path /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
sudo shutdown -r now

launchctl getenv PATH
cat /etc/paths

sudo xcodebuild -license accept
DevToolsSecurity -enable

# Show basic system info at the login screen
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Show hidden files
defaults write com.apple.finder AppleShowAllFiles TRUE; killall Finder

# enable text selection in quick look windows
defaults write com.apple.finder QLEnableTextSelection -bool TRUE;killall Finder

# remove the auto-hide dock delay
defaults write com.apple.Dock autohide-delay -float 0 && killall Dock
# minize mode
defaults write com.apple.dock mineffect suck; Killall Dock
# highlight icon
defaults write com.apple.dock mouse-over-hilite-stack -bool TRUE; killall Dock
# remove none-opened icons
defaults write com.apple.dock static-only -boolean true; killall Dock
# hidden icons
defaults write com.apple.dock showhidden -bool true; Killall Dock

defaults write -g ApplePressAndHoldEnabled -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# set safari default font size
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2MinimumFontSize -int 18

for pkg in /Applications/Xcode.app/Contents/Resources/Packages/*.pkg; do
  sudo installer -pkg "$pkg" -target /;
done

sudo chown -R `whoami`:admin /usr/local
ls -altrh /usr/
ls -lO /usr/

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap caskroom/versions
brew tap homebrew/dupes
brew tap homebrew/python
brew update

which -a brew
whereis brew
git -C "$(brew --repo homebrew/core)" fetch --unshallow
brew install bash
which -a bash
/usr/local/bin/bash --version

brew install wget tmux corkscrew tig bash-completion ifstat binutils diffutils gawk gnutls gzip file-formula stow telnet iproute2mac

brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
brew install grep --with-default-names
brew install ed --with-default-names
brew install findutils --with-default-names
brew install wdiff --with-gettext

brew install vim --override-system-vi
brew install macvim --override-system-vim --custom-system-icons

brew cask install iterm2-beta
brew install git

echo "if [ -f $(brew --prefix)/etc/bash_completion ]; then" >> ~/.bash_profile
echo "  . $(brew --prefix)/etc/bash_completion" >> ~/.bash_profile
echo "fi" >> ~/.bash_profile

chmod go-w /usr/local/opt

sudo bash -c 'echo "/usr/local/bin/bash" >> /etc/shells'
chsh -s /usr/local/bin/bash
sudo chsh -s /usr/local/bin/bash

push .
cd ~/mywork/tools/git/repo_tools/
git clone https://github.com/tj/n
cd n
sudo chown -R `whoami`:admin /usr/local
make install
which -a n
popd

sudo scutil --set HostName mj
sudo scutil --set LocalHostName mj
sudo scutil --set ComputerName marslo

networksetup -setv6off Ethernet
networksetup -setv6off Wi-Fi

sudo updatedb
