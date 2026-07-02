#!/usr/bin/env bash
# shellcheck disable=SC2021
#=============================================================================
#     FileName : checkNIC.sh
#       Author : marslo
#      Created : 2024-10-21 16:03:41
#   LastChange : 2026-07-01 18:02:55
#=============================================================================

set -euo pipefail

declare DNS=false
declare usage="USAGE
  $0 [OPTIONS]

OPTIONS
  --dns       show DNS information for the network interface
  -h, --help  show this help message and exit
"

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --dns       ) DNS=true; shift ;;
    -h | --help ) echo -e "${usage}"; exit 0 ;;
    *           ) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# echo -e "| HOSTNAME | BANDWIDTH | INTERFACE | IP_ADDRESS | MAC_ADDRESS | DNS_TOOL |"

declare interface macaddress ipaddress bandwidth dnstool='n/a'
# interface="$(/bin/ip route show default | awk '{print $5; exit}')"
# interface="$(/bin/ip route get "$(dig +short github.com | head -1)" | sed -rn 's|.*dev\s+(\S+)\s+src.*$|\1|p')"
interface="$(/bin/ip -o route get 1.1.1.1 2>/dev/null | sed -rn 's|.*\bdev\s+(\S+).*|\1|p')"
macaddress="$(/bin/ip link show "${interface}" | sed -rn 's|.*ether ([0-9a-fA-F:]{17}).*$|\1|p' | tr '[a-z]' '[A-Z]')"
ipaddress=$(/bin/ip -4 a s "${interface}" | sed -nE 's/^[[:space:]]*inet[[:space:]]+([0-9]{1,3}(\.[0-9]{1,3}){3})\/[0-9]{1,2}.*/\1/p' | paste -sd/ -)
bandwidth=$(type -P ethtool >/dev/null 2>&1 && sudo /sbin/ethtool "${interface}"| sed -rn 's|\s*Speed:\s*(.+)$|\1|p' || echo 'N/A')
case "${bandwidth}" in
  10000Mb/s ) bandwidth="\033[1;32m${bandwidth}\033[0m" ;;
  N/A       ) bandwidth="\033[1;31m${bandwidth}\033[0m" ;;
esac
if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
  if   type -P resolvectl      >/dev/null 2>&1; then dnstool='resolvectl'
  elif type -P systemd-resolve >/dev/null 2>&1; then dnstool='systemd-resolve'
  fi
fi
echo -e "| \033[1;36m$(hostname)\033[0m | ${bandwidth} | ${interface} | ${ipaddress} | ${macaddress} | ${dnstool} |"

"${DNS}" && {
  case "${dnstool}" in
    resolvectl      ) resolvectl status "${interface}"        ;;
    systemd-resolve ) systemd-resolve --status "${interface}" ;;
    *               ) echo -e "\033[1;31mWARN\033[0m: systemd-resolved is not active; no resolvectl/systemd-resolve available" >&2 ;;
  esac
} || :

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh
