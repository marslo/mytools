#!/usr/bin/env bash
# shellcheck disable=SC2086

# credit belongs to https://raw.githubusercontent.com/ppo/bash-colors/master/bash-colors.sh
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\e[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\e[\1m/g'; }
exitOnError() { if [ $? -ne 0 ]; then echo -e "$(c R)ERROR$(c) : $*" >&2; exit 1; fi; }
showHelp() { echo -e "${usage}"; exit 0; }

usage="""
\t $(c R)nsb$(c) - $(c iR)n$(c)ame$(c iR)s$(c)pace $(c iR)b$(c)ackup: to backup all available api-resources in given namespace
\nSYNOPSIS:
\n\t$(c sY)\$ nsb <namespace> [<namespace> [<namespace> [..]]]$(c)
\nEXAMPLE:
\n\tshow help
\t\t$(c G)\$ nsb$(c)
\n\tbackup namespace(s)
\t\t$(c G)\$ nsb <namespace> <namespace> <namespace> ...$(c)
"""

[[ 0 -eq $# ]] && showHelp
path="./backups-$(date +%Y%m%d)/namespace"

while read -r -d' ' ns; do

  echo -e "\n\n\n================================ $(c iY)${ns}$(c) ================================"
  for _ar in $(kubectl api-resources --verbs=list --namespaced -o name); do
    if [[ "$(kubectl -n ${ns} get ${_ar} 2>&1)" = No* ]]; then
      :
    else
      target="${path}/${ns}/${_ar}"
      mkdir -p "${target}"

      echo -e "\n----- $(c iY)${ns}$(c) : $(c iB)${_ar}$(c) ------"
      kubectl -n ${ns} get ${_ar} | tee "${target}/status.log"
      kubectl -n ${ns} describe ${_ar} > "${target}/${_ar}.describe.log"

      echo -e "\n... backup $(c iB)${_ar}$(c) all to ${target}/${_ar}.yml"
      kubectl -n ${ns} get ${_ar} -o yaml --export > "${target}/${_ar}.yml"

      while read -r name; do
        echo -e "\t... backup $(c iB)${_ar}$(c) $(c iG)${name}$(c) to ${target}/${name}.yml"
        if [[ "${name}" =~ .*-token-.* ]]; then
          kubectl -n ${ns} get ${_ar} ${name} -o yaml > ${target}/${name}.yml
        else
          kubectl -n ${ns} get ${_ar} ${name} -o yaml --export > ${target}/${name}.yml
        fi
      done < <(kubectl -n "${ns}" get "${_ar}" -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}')

    fi
  done

  echo -e "======================================================================="
done <<< "$* "
