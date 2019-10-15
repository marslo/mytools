#!/bin/bash
# inspired from https://stackoverflow.com/a/4413917/2940319

export ID=YourAppleID
export PW=YourPW

[ -f cookies ] && rm cookies && touch cookies

2>Header \
wget \
-S \
-O R1 \
http://developer.apple.com/ios/download.action?path=/ios/ios_sdk_4.2__final/xcode_3.2.5_and_ios_sdk_4.2_final.dmg

tac Header | grep Location
LOCATION=$(grep Location Header | sed -E 's/^ *Location: ([^/]+:\/\/[^/]+)\/.*$/\1/')
[ -z "$LOCATION" ] && { echo "Bad day for LOCATION...";exit;} || echo "LOCATION=$LOCATION"
rm Header

ACTION=$(grep action R1 | sed 's/^.*action="//;s/".*$//')
[ -z "$ACTION" ] && { echo "Bad day for ACTION...";exit;} || echo "ACTION=$ACTION"

POST=$( grep input R1 | sed 's/<input/\
<input/g' | grep input | sed 's/^.*name="//' | sed 's/".*value="/=/;s/".*$//' | sed '/=/!s/$/=/' | sed '/theAccountName/s/$/'$ID'/;/theAccountPW/s/$/'$PW'/' | sed '/=$/d' | sed -n '1h;1!H;${x;s/[[:space:]]/\&/g;p;}' | sed  's/$/\&1.Continue.x=0\&1.Continue.y=0/')
[ -z "$POST" ] && { echo "Bad day for POST...";exit;} || echo "POST=$POST"

2>Header \
wget \
-S \
--save-cookies cookies \
--keep-session-cookies \
-O R2 \
--post-data="$POST" \
$LOCATION/$ACTION

URL=$( grep -i REFRESH R2 | sed 's/^.*URL=//;s/".*$//' )
[ -z "$URL" ] && { echo "Bad day for URL...";exit;} || echo "URL=$URL"

wget \
-S \
--load-cookies cookies \
$URL &

sleep 1; rm R1 R2 Header cookies
