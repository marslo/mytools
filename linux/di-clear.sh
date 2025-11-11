#!/usr/bin/env bash
#=============================================================================
#     FileName : di-clear.sh
#       Author : marslo
#      Created : 2025-11-06 21:46:24
#   LastChange : 2025-11-07 02:41:57
#=============================================================================

set -euo pipefail

declare ME="${SCRIPT_NAME:-$(basename "${BASH_SOURCE[0]:-di-clear.sh}")}"

# shellcheck disable=SC2155
declare TAG=''
declare SHOW=false
declare usage="""
USAGE
  \033[1;36m\$ ${ME} \033[0;3;32m[ OPTIONS ]\033[0m

OPTIONS
  \033[0;3;32m-t\033[0m, \033[0;3;32m--tag \033[0;3;35m<tag>\033[0m    specify the tag of the Docker images to be removed.
  \033[0;3;32m-s\033[0m, \033[0;3;32m--show\033[0m         show the Docker images with the specified tag before removal.
  \033[0;3;32m-h\033[0m, \033[0;3;32m--help\033[0m         show this help message and exit.

EXAMPLE
  \033[2;3;37m# remove image with knrun/rrun tool\033[0m
  \033[1;36m\$ knrun \033[0;3;35m-f ${ME} -v \033[0;3;34m-- \033[0;3;32m-t '4.1.1' -s\033[0m
"""

while [[ $# -gt 0 ]]; do
  case $1 in
    -t | --tag  ) TAG="$2"; shift 2 ;;
    -s | --show ) SHOW=true; shift;;
    -h | --help ) echo -e "${usage}"; exit 0 ;;
    *           ) echo -e "\033[3;1;31mUnknown argument: \`$1\`\033[0m" >&2; exit 1 ;;
  esac
done

function info()  { echo -e "\033[3;1;34m>> INFO: $*\033[0m"; }
function alert() { echo -e "\033[3;1;30;38;5;174m>> ALERT: $*\033[0m"; }
function error() { echo -e "\033[3;1;31mERROR\033[0m\033[3;37m: $*\033[0m" >&2; }

test -z "${TAG}" && { error "tag must be specified with \`-t\` or \`--tag\` !"; exit 1; }

"${SHOW}" && {
  info "showing docker images with tag \`${TAG}\` ...";
  docker images --format '{{.Repository}}:{{.Tag}}\t{{.ID}}' | command grep -F "${TAG}" | column -t;
}

alert "removing images with tag \`${TAG}\` ..."
docker images --format '{{.Tag}}\t{{.ID}}' |
       command grep -F "${TAG}" | command awk '{print $2}' | uniq |
       xargs -r docker rmi -f

alert "removing dangling images ..."
docker images -f dangling=true -q | uniq | xargs -r docker rmi -f

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
