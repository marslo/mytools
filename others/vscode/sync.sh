#!/usr/bin/env bash

basePath='/Users/marslo/Library/Application Support/Code/User'
snippetsPath="${basePath}"/sync/snippets
extensionsPath="${basePath}"/sync/extensions
globalStatePath="${basePath}"/sync/globalState

CP="/usr/local/opt/coreutils/libexec/gnubin/cp"
JQ="/usr/local/bin/jq"
MD5SUM="/usr/local/opt/coreutils/libexec/gnubin/md5sum"
DIFF="/usr/local/bin/diff"

c() {
  # shellcheck disable=SC1009,SC2015
  [ $# -eq 0 ] && echo "\033[0m" || echo "$1" | sed -E "s/(.)/‹\1›/g;s/([KRGYBMCW])/3\1/g;s/([krgybmcw])/4\1/g;s/S/22/;y/sufnKRGYBMCWkrgybmcw›/14570123456701234567m/;s/‹/\\\033[/g";
}

function doCopy() {
  if [ 2 -ne $# ]; then
    echo "copy required two arguments"
    exit 1
  fi

  sourceFile="$1"
  targetFile="$2"

  if [ ! -f "${sourceFile}" ]; then
    echo "${sourceFile} does NOT exist"
    exit 2
  fi
  if [[ ! -d "$(dirname "${targetFile}")" ]]; then
    echo "$(dirname "${targetFile}") does NOT exist"
    exit 3
  fi


  baseHash="""$("${MD5SUM}" "${sourceFile}" | awk NF=1)"""
  if [[ -f "${targetFile}" ]]; then
    targetHash="""$("$MD5SUM" "${targetFile}" | awk NF=1)"""
  else
    targetHash=''
  fi


  if [[ -z "${targetHash}" ]]; then
    echo -e "$(c B)'${targetFile}' does not exist. copy directly$(c)"
    yes | "${CP}" --force "${sourceFile}" "${targetFile}"
  elif [[ "${baseHash}" = "${targetHash}" ]]; then
    echo -e "$(c sY)IGNORE: both md5 are '${baseHash}'$(c).\n ... '${sourceFile}' same as '${targetFile}' ... "
  else
    echo -e "$(c G)COPY: '${sourceFile}' to '${targetFile}'$(c).\ndifference are:"
    "${DIFF}" --color=always "${sourceFile}" "${targetFile}"
    yes | "${CP}" --force "${sourceFile}" "${targetFile}"
  fi

}

doCopy "${basePath}/settings.json"          "./settings.json"
doCopy "${basePath}/settings.json"          "./settings.json"
doCopy "${basePath}/keybindings.json"       "./keybindings.json"
doCopy "${basePath}/syncLocalSettings.json" "./syncLocalSettings.json"

if [[ -n """$("${JQ}" -r ".content|select(.!=null)" "${snippetsPath}"/lastSyncsnippets.json)""" ]]; then
  doCopy "${snippetsPath}/lastSyncsnippets.json" "./snippets.json"
fi

if [[ -n """$("${JQ}" -r ".content|select(.!=null)" "${extensionsPath}"/lastSyncextensions.json)""" ]]; then
  doCopy "${extensionsPath}/lastSyncextensions.json" "./extensions.json"
fi

if [[ -n """$("${JQ}" -r ".content|select(.!=null)" "${globalStatePath}"/lastSyncglobalState.json)""" ]]; then
  doCopy "${globalStatePath}/lastSyncglobalState.json" "./globalState.json"
fi
