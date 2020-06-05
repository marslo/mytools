#!/usr/bin/env bash
# shellcheck disable=SC1078,SC1079

usage="""mg - marslo grep - combined find and grep to quick find keywords
\nUSAGE:
\n\t\$ mg [OPT] KEYWORD [<PATHA>]
\nExample:
\n\t\$ mg 'hello'
\t\$ mg i 'hello' ~/.marslo
\nOPT:
\n\ti: ignore case
\tf: find file name only
"""

kw=''
p='.'
opt='-n -H -E --color=always'

if [ 0 -eq $# ]; then
  echo -e "${usage}"
else
  case $1 in
    [iI] )
      opt="${opt} -i"
      kw="$2"
      [ 3 -eq $# ] && p="$3"
      ;;

    [fF] )
      opt="${opt} -l"
      kw="$2"
      [ 3 -eq $# ] && p="$3"
      ;;

    [iI][fF] | [fF][iI] )
      opt="${opt} -i -l"
      kw="$2"
      [ 3 -eq $# ] && p="$3"
      ;;

    * )
      kw="$1"
      [ 2 -le $# ] && p="$2"
      ;;
  esac

  if [ -n "${kw}" ]; then
    find "${p}" -type f -not -path "\'*git/*\'" -exec grep "${opt}" "${kw}" {} \;
  else
    echo -e "${usage}"
  fi
fi
