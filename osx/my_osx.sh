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

brew install wget tmux corkscrew tig bash-completion ifstat binutils diffutils gawk gnutls gzip file-formula stow telnet iproute2mac ctags jq colordiff tree vifm p7zip git mas htop

brew install gnu-sed --with-default-names
brew install gnu-tar --with-default-names
brew install gnu-which --with-default-names
brew install grep --with-default-names
brew install ed --with-default-names
brew install findutils --with-default-names
brew install wdiff --with-gettext

brew install vim --override-system-vi

brew cask install moom dash little-snitch growl-fork iterm2-beta firefox google-chrome  # or $ brew cask install google-chrome-dev
brew cask install macvim --override-system-vim --custom-system-icons

brew install berkeley-db jack libmad libid3tag ffmpeg         # jackd -d coreaudio
brew install moc --with-ncurses

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

pip install rainbow
pip install colout2

sudo updatedb


cat << 'EOF' > ~/Library/LaunchAgents/i.marslo.mocjackd.plist
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <dict>
        <key>Label</key>
        <string>i.marslo.mocjackd</string>
        <key>WorkingDirectory</key>
        <string>/Users/marslo/</string>
        <key>ProgramArguments</key>
        <array>
            <string>/usr/local/bin/jackd</string>
            <string>-d</string>
            <string>coreaudio</string>
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

launchctl load ~/Library/LaunchAgents/i.marslo.mocjackd.plist
launchctl load ~/Library/LaunchAgents/i.marslo.mocgrowl.plist
sudo launchctl unload -w /Library/LaunchDaemons/at.obdev.littlesnitchd.plist

mas login marslo.jiao@gmail.com

mas install 1256503523
mas install 836500024
mas install 1233593954
mas install 467939042
mas install 497799835
mas install 736473980
mas install 520993579
mas install 944848654
mas install 419330170
