#!/usr/bin/env bash # =============================================================================
#     FileName : calculateSize.sh
#       Author : marslo.jiao@gmail.com
#      Created : 2021-08-18 21:21:36
#   LastChange : 2021-08-18 22:55:03
# Useful Links :
#                - https://gist.github.com/sanjeevtripurari/6a7dbcda15ae5dec7b56
#                - https://stackoverflow.com/a/19060079/2940319
#                - https://raw.githubusercontent.com/ppo/bash-colors/master/bash-colors.sh
# =============================================================================

rod='1024'
remainder='2'
domain='my.artifactory.com'
verbose='false'

c() {
  # shellcheck disable=SC1009,SC2015
  [ $# -eq 0 ] && echo "\033[0m" || echo "$1" | sed -E "s/(.)/‹\1›/g;s/([KRGYBMCW])/3\1/g;s/([krgybmcw])/4\1/g;s/S/22/;y/sufnKRGYBMCWkrgybmcw›/14570123456701234567m/;s/‹/\\\033[/g";
}

usage() {
  usage="""
  $0 - calculate repo size in Artifactory
  \nSYNOPSIS
  \t$(c sY)\$ $0 [-v] [-h] [-d <domain>]$(c)
  \nEXAMPLE
  \n\t$(c G)\$ $0 -v -d my.artifactory.com
  \t\$ $0 -d my.artifactory.com $(c)
  \nOPT:
  \n\t$(c B)-v$(c) : show repo details (verbose)
  \t$(c B)-h$(c) : help
  \t$(c B)-d$(c) : domain name setup
  """

  echo -e "${usage}" 1>&2
  exit 1
}

toBytes() {
  size=$1
  unit=$2
  case ${unit} in
    [bB][yY][tT][eE][sS] ) b="${size}" ;;
    [kK][bB] ) b=$( multiplication "${size}" "${rod}" ) ;;
    [mM][bB] ) b=$( multiplication "${size}" "${rod}^2" ) ;;
    [gG][bB] ) b=$( multiplication "${size}" "${rod}^3" ) ;;
    [tT][bB] ) b=$( multiplication "${size}" "${rod}^4" ) ;;
  esac
  echo "${b}"
}

multiplication() {
  multiplicant=$1
  multiplier=$2
  echo $( bc <<< "${multiplicant} * ${multiplier}" )
}

division() {
  divident=$1
  divisor=$2
  echo $( bc <<< "scale=${remainder}; ${divident} / ${divisor}" )
}

roundUp() {
 printf '%.*f\n' 0 "$1"
}

humanForamt() {
  while read -r B; do
    [ $( roundUp ${B} ) -lt ${rod}  ] && echo ${B} bytes && break
    KB=$( division "${B}" "${rod}"  )
    [ $( roundUp ${KB} ) -lt ${rod} ] && echo ${KB} KB && break
    MB=$( division "${KB}" "${rod}" )
    [ $( roundUp ${MB} ) -lt ${rod} ] && echo ${MB} MB && break
    GB=$( division "${MB}" "${rod}" )
    [ $( roundUp ${GB} ) -lt ${rod} ] && echo ${GB} GB && break
    TB=$( division "${GB}" "${rod}" )
    echo "${TB} TB"
  done < <( echo "$1" )
}

main() {
  sumBytes=0
  declare -i amount=0
  [ 'true' == "${verbose}" ] && echo -e '\n    repo used space details: '
  while read -r size unit repo; do
    [ 'true' == "${verbose}" ] && echo -e """\t$(c M)${size} ${unit}$(c) :\t${repo} """
    amount+=1
    size=$( echo ${size} | sed 's:,::' )
    sumBytes=$( bc -l <<< "${sumBytes} + $(echo $(toBytes ${size} ${unit}))" )
  # done < <( cat "$1" )
  done < <( curl -sSg --netrc-file ~/.marslo/.netrc ${url} |
                jq -r '.repositoriesSummaryList[] | select(.repoType == "LOCAL") | .usedSpace + " " + .repoKey' |
                sort -rg
          )

  total=$( humanForamt ${sumBytes} )
  echo -e """
    Total used space in ${domain}: $(c sG)${total}$(c)
    There's $(c sG)${amount}$(c) Local repos
    average used space for each local repo is: $(c sG)$( humanForamt $( division ${sumBytes} ${amount} ))$(c)
  """
}

while getopts "hvd:" opts; do
  case "${opts}" in
    v ) verbose='true' ;;
    d ) domain=${OPTARG} ;;
    h | * ) usage ;;
  esac
done

if [ 0 -eq $# ]; then
  echo -e "$(c sY)~~> INFO: domain name have been set by '-d'. using the default domain name: ${domain}$(c)"
elif [ 1 -eq $# ]; then
  [ '-v' != "$1" ] || [ '-h' != "$1" ] && domain="$1" && echo -e "$(c sY)~~> INFO: using domain name : ${domain}$(c)"
fi

url="https://${domain}/artifactory/api/storageinfo"

main
