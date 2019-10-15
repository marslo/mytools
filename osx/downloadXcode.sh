#!/bin/bash
# inspired from https://stackoverflow.com/a/4719807/2940319

# Change this line to the URI path of the xcode DMG file.
XCODE_PATH="/ios/ios_sdk_4.2__final/xcode_3.2.5_and_ios_sdk_4.2_final.dmg"

echo "Enter your Apple Dev Center username."
read -p "> " USERNAME
echo "Enter your Apple Dev Center password."
read -p "> " PASSWORD

curl \
        -L -s -k \
        --cookie-jar cookies \
        -A "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1) Gecko/20090624 Firefox/3.5" \
        https://developer.apple.com/devcenter/ios/login.action \
        -o login.html

ACTION=$(sed -n 's/.*action="\(.*\)".*/\1/p' login.html)
WOSID=$(sed -n 's/.*wosid" value="\(.*\)".*/\1/p' login.html)
echo "action=${ACTION}"
echo "wosid=${WOSID}"

curl \
        -s -k --cookie-jar cookies --cookie cookies \
        -A "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1) Gecko/20090624 Firefox/3.5" \
        -e ";auto" "https://daw.apple.com${ACTION}?theAccountName=${USERNAME}&theAccountPW=${PASSWORD}&theAuxValue=&wosid=${WOSID}&1.Continue.x=0&1.Continue.y=0" \
        > /dev/null

curl \
        -L --cookie-jar cookies --cookie cookies \
        -A "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.5; en-US; rv:1.9.1) Gecko/20090624 Firefox/3.5" \
        -O https://developer.apple.com/ios/download.action?path=${XCODE_PATH}

rm login.html
rm cookies

# Links:
# inspired from https://stackoverflow.com/a/44390183/2940319

# 11.2
# https://developer.apple.com/services-account/download?path=/Developer_Tools/Xcode_11.2_beta_2/Xcode_11.2_beta_2.xip
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_for_Xcode_11.2_beta_2/Command_Line_Tools_for_Xcode_11.2_beta_2.dmg

# 11.1
# https://developer.apple.com/services-account/download?path=/Developer_Tools/Xcode_11/Xcode_11.xip
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_for_Xcode_11/Command_Line_Tools_for_Xcode_11.dmg

# 10.2.1
# https://download.developer.apple.com/Developer_Tools/Xcode_10.2.1/Xcode_10.2.1.xip
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.14_for_Xcode_10.2.1.dmg/Command_Line_Tools_macOS_10.14_for_Xcode_10.2.1.dmg
# https://itunes.apple.com/us/app/xcode/id497799835

# 10.2
# https://download.developer.apple.com/Developer_Tools/Xcode_10.2/Xcode_10.2.xip
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.14_for_Xcode_10.2/Command_Line_Tools_macOS_10.14_for_Xcode_10.2.dmghttps://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.14_for_Xcode_10.2/Command_Line_Tools_macOS_10.14_for_Xcode_10.2.dmg

# 10.1
# https://download.developer.apple.com/Developer_Tools/Xcode_10.1/Xcode_10.1.xip
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.14_for_Xcode_10.1/Command_Line_Tools_macOS_10.14_for_Xcode_10.1.dmg
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.13_for_Xcode_10.1/Command_Line_Tools_macOS_10.13_for_Xcode_10.1.dmg

# 10
# https://download.developer.apple.com/Developer_Tools/Xcode_10/Xcode_10.xip
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.13_for_Xcode_10/Command_Line_Tools_macOS_10.13_for_Xcode_10.dmg
# https://download.developer.apple.com/Developer_Tools/Command_Line_Tools_macOS_10.14_for_Xcode_10/Command_Line_Tools_macOS_10.14_for_Xcode_10.dmg

# 9
# https://download.developer.apple.com/Developer_Tools/Xcode_9.4.1/Xcode_9.4.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_9.3.1/Xcode_9.3.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_9.3/Xcode_9.3.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_9.2/Xcode_9.2.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_9.1/Xcode_9.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_9.0.1/Xcode_9.0.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_9.0/Xcode_9.0.xip

# 8
# https://download.developer.apple.com/Developer_Tools/Xcode_8.3.3/Xcode8.3.3.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8.3.2/Xcode8.3.2.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8.3.1/Xcode_8.3.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8.3/Xcode_8.3.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8.2.1/Xcode_8.2.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8.2/Xcode_8.2.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8.1/Xcode_8.1.xip
# https://download.developer.apple.com/Developer_Tools/Xcode_8/Xcode_8.xip
