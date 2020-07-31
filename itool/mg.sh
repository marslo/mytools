# marslo grep
function mg() {
  usage="""mg - marslo grep - combined find and grep to quick find keywords
  \nUSAGE:
  \n\t$(c sY)\$ mg [OPT] [NUM] KEYWORD [<PATHA>]$(c)
  \nExample:
  \n\t$(c G)\$ mg 'hello'
  \t\$ mg i 'hello' ~/.marslo
  \t\$ mg ic 3 'hello' ~/.marslo$(c)
  \nOPT:
  \n\t$(c B)i$(c) : ignore case
  \t$(c B)f$(c) : find file name only
  \t$(c B)a <num>$(c) : print <num> lines of trailing context after matching lines
  \t$(c B)b <num>$(c) : print <num> lines of leading context before matching lines
  \t$(c B)c <num>$(c) : print <num> lines of output context
  """

  kw=''
  p='.'
  opt='-n -H -E --color=always'

  if [ 0 -eq $# ]; then
    echo -e "${usage}"
  else
    case $1 in
      [wW] | [iI] )
        opt="${opt} -$(echo $1 | tr '[:upper:]' '[:lower:]')"
        [ 2 -le $# ] && kw="$2"
        [ 3 -eq $# ] && p="$3"
        ;;
      [fF] )
        opt="${opt} -l"
        [ 2 -le $# ] && kw="$2"
        [ 3 -eq $# ] && p="$3"
        ;;
      [iI][fF] | [fF][iI] )
        opt="${opt} -i -l"
        [ 2 -le $# ] && kw="$2"
        [ 3 -eq $# ] && p="$3"
        ;;
      [aA] | [bB] | [cC] | [iI][aA] | [iI][bB] | [iI][cC] | [aA][iI] | [bB][iI] | [cC][iI] )
        # line = -A $2 | -B $2 | -C $2
        line="-$(echo $1 | awk -F'[iI]' '{print $1,$2}' | sed -e 's/^[[:space:]]*//' | tr '[:lower:]' '[:upper:]') $2"
        opt="${opt} -i ${line}"
        [ 3 -le $# ] && kw="$3"
        [ 4 -eq $# ] && p="$4"
        ;;
      * )
        kw="$1"
        [ 2 -le $# ] && p="$2"
        ;;
    esac

    if [ -n "${kw}" ]; then
      # or using + instead of ; details: https://unix.stackexchange.com/a/43743/29178
      cmd="""find "${p}" -type f -not -path "*git/*" -exec ${GREP} ${opt} "${kw}" {} ;"""
      find "${p}" -type f -not -path "*git/*" -exec ${GREP} ${opt} "${kw}" {} \; \
        || echo -e """\n$(c Y)ERROR ON COMMAND:$(c)\n\t$(c R)$ ${cmd}$(c) """
    else
      echo -e "${usage}"
    fi
  fi
}

