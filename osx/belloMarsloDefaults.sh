#!/bin/bash
# shellcheck disable=SC2034
# =============================================================================
#    FileName: belloMarsloDefaults.sh
#      Author: marslo.jiao@philips.com
#     Created: 2018-02-27 13:48:08
#  LastChange: 2019-06-04 20:11:14
# =============================================================================

modifierNoOp=0
modifierMissionCtl=2
modifierApplicationWindows=3
modifierDesktop=4
modifierStartScreenSaver=5
modifierDisableScreenSaver=6
modifierDashboard=7
modifierDisplayToSleep=10
modifierLaunchpad=11

modifierNone=0
modifierShift=131072
modifierControl=262144
modifierOption=524288
modifierCmd=1048576

sudo /usr/sbin/systemsetup -settimezone $TIMEZONE
sudo /usr/sbin/systemsetup -setnetworktimeserver "time.asia.apple.com"
sudo /usr/sbin/systemsetup -setusingnetworktime on
sudo systemsetup -setcomputersleep Off

############
## System ##
############
# Setup login window text
sudo defaults write /Library/Preferences/com.apple.loginwindow LoginwindowText "Awesome Marslo !!"
# Set language
defaults write -g AppleLanguages -array 'en'
# Set measurement units
defaults write -g AppleMeasurementUnits -string 'Centimeters'
# Hide battery percentage from the menu bar
defaults write com.apple.menuextra.battery ShowPercent -string 'NO'
# disable dashboard
defaults write com.apple.dashboard mcx-disabled -boolean YES
# Disable system sleep
sudo systemsetup -setcomputersleep Never
# sounds
defaults write .GlobalPreferences com.apple.sound.beep.sound /System/Library/Sounds/Tink.aiff
defaults write .GlobalPreferences com.apple.sound.beep.volume "0.5"

# Press repet key
defaults write -g ApplePressAndHoldEnabled -bool false
# Enable full keyboard access for all controls (e.g. enable Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3
# Keyboard -> Adjust keyboard brightness in low light
defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Automatic Keyboard Enabled" -bool true
defaults write /Library/Preferences/com.apple.iokit.AmbientLightSensor "Keyboard Dim Time" -int 300
# Keyboard Layout
defaults write /Library/Preferences/com.apple.HIToolbox AppleCurrentKeyboardLayoutInputSourceID "com.apple.keylayout.ABC"
defaults write /Library/Preferences/com.apple.HIToolbox AppleDefaultAsciiInputSource -dict InputSourceKind "Keyboard Layout" "KeyboardLayout ID" -int 252 "KeyboardLayout Name" ABC
# Turn autocorrect on
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool true

# Show basic system info at the login screen
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName
# Enable tap to click (Trackpad)
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
# Map bottom right Trackpad corner to right-click
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadCornerSecondaryClick -int 2
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool true
# Enable the debug menu in iCal
defaults write com.apple.iCal IncludeDebugMenu -bool true
# Disable resume system-wide
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
# make textEditor to plain text
defaults write com.apple.TextEdit RichText -int 0
# Make the save panel expanded by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
# Save screenshots to the Desktop
defaults write com.apple.screencapture location -string "$HOME/Desktop"
# Save screenshots as PNGs
defaults write com.apple.screencapture type -string 'png'

killall "SystemUIServer"


###############
## Developer ##
###############
# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4
# enable SSH
sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
# Disable the “Are you sure you want to open this application?” dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false
# enable VNC
# sudo /System/Library/CoreServices/RemoteManagement/ARDAgent.app/Contents/Resources/kickstart -activate -configure -access -on -clientopts -setvnclegacy -vnclegacy yes -clientopts -setvncpw -vncpw PutYourOwnPasswordHere -restart -agent -privs -all

##############
## AppStore ##
##############
# Check update daily
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
# Install System data files and security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
# Enable automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

killall "App Store"


############
## Safari ##
############
# set safari default font size
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2MinimumFontSize -int 18
# Enable Safari’s debug menu
defaults write com.apple.Safari IncludeDebugMenu -bool true
# Remove useless icons from Safari’s bookmarks bar
defaults write com.apple.Safari ProxiesInBookmarksBar "()"
# Enable the 'Develop' menu and the 'Web Inspector'
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
# Set home page to 'about:blank'
defaults write com.apple.Safari HomePage -string 'about:blank'
# Enable 'Debug' menu
defaults write com.apple.Safari IncludeInternalDebugMenu -bool true
# Show bookmarks bar by default
defaults write com.apple.Safari ShowFavoritesBar -bool true
# Show the full URL in the address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true


############
## Finder ##
############
# Disable warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
# Disable warning when move file from icloud driver
defaults write com.apple.finder FXEnableRemoveFromICloudDriveWarning -bool false
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles TRUE
# enable text selection in quick look windows
defaults write com.apple.finder QLEnableTextSelection -bool TRUE
# Use full POSIX path as window title
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false
# Disable .DS_Store in Finder
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
# Disable the .DS_Store in USB
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
# Set default view as Column View
defaults write com.apple.finder FXPreferredViewStyle -string 'clmv'
# Set the $HOME as default Finder
defaults write com.apple.finder NewWindowTarget -string "PfLo" && \
  defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}"
# search scop to current folder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"
# Show path
defaults write com.apple.finder ShowPathbar -bool true
# Show scrollbar 'Always', 'Automatic', 'WhenScrolling'
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"
# Allow quitting Finder via ⌘ + Q
defaults write com.apple.finder QuitMenuItem -bool true
# status bar
defaults write com.apple.finder ShowStatusBar -bool true
# Set column view
/usr/libexec/PlistBuddy -c 'Set :StandardViewOptions:ColumnViewOptions:FontSize 16' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewOptions:ColumnViewOptions:ColumnWidth 280' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewOptions:ColumnViewOptions:ArrangeBy modd' ~/Library/Preferences/com.apple.finder.plist
# Set list view
/usr/libexec/PlistBuddy -c 'Set :ComputerViewSettings:ListViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :ComputerViewSettings:ListViewSettings:sortColumn dateModified;' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:ListViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:ListViewSettings:sortColumn dateModified;' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :PackageViewSettings:ListViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :PackageViewSettings:ListViewSettings:sortColumn dateModified;' ~/Library/Preferences/com.apple.finder.plist
# Set icon view
/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:iconSize 72' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:iconSize 72' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :DesktopViewSettings:IconViewSettings:arrangeBy dateModified' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:textSize 16' ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c 'Set :StandardViewSettings:IconViewSettings:arrangeBy dateModified' ~/Library/Preferences/com.apple.finder.plist

killall Finder
killall cfprefsd


##########
## Dock ##
##########
# auto hide dock
defaults write com.apple.dock autohide -bool true
# remove the auto-hide dock delay
defaults write com.apple.dock autohide-delay -float 0
# minize mode
defaults write com.apple.dock mineffect suck
# highlight icon
defaults write com.apple.dock mouse-over-hilite-stack -bool TRUE
# remove none-opened icons
defaults write com.apple.dock static-only -boolean true
# hidden icons
defaults write com.apple.dock showhidden -bool true
# Set icon size
defaults write com.apple.dock tilesize -int 50
# Show indicator lights for open applications
defaults write com.apple.dock show-process-indicators -bool true
# Hot cornor
# Top right screen corner →  Mission Control
defaults write com.apple.dock wvous-tr-corner -int ${modifierMissionCtl}
defaults write com.apple.dock wvous-tr-modifier -int ${modifierNone}
# Bottom right screen corner →  application windows
defaults write com.apple.dock wvous-br-corner -int ${modifierApplicationWindows}
defaults write com.apple.dock wvous-br-modifier -int ${modifierNone}
# Bottom left screen corner →  Desktop
defaults write com.apple.dock wvous-bl-corner -int ${modifierDesktop}
defaults write com.apple.dock wvous-bl-modifier -int ${modifierNone}

killall Dock
