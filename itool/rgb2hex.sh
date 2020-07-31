#!/bin/bash

CURL_OPT="-x 127.0.0.1:1087 -fsSL -O"

# get details from https://github.com/marslo/mytools/tree/master/others/iterm2
[ -f csscolors.js ] || curl ${CURL_OPT} https://raw.githubusercontent.com/jonathaneunice/iterm2-tab-set/master/csscolors.js
while read -r i; do
  rgb=$(grep -E "\s$i:" csscolors.js | sed -re "s:.*\[(.*)\],?$:\1:";)
  hexc=$(for c in $(echo "${rgb}" | sed -re 's:,::g'); do printf '%02x' "$c"; done)
  echo -e """ $i :\t$rgb :\t$hexc """
  # echo "$hexc" >> ~/.marslo/.it2color
done < ~/.marslo/.colors
