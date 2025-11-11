#!/usr/bin/env bash
# shellcheck disable=SC2021
#=============================================================================
#     FileName : checkNIC.sh
#       Author : marslo
#      Created : 2024-10-21 16:03:41
#   LastChange : 2025-11-05 14:26:21
#=============================================================================

set -euo pipefail

# echo -e "| HOSTNAME | BANDWIDTH | INTERFACE | IP_ADDRESS | MAC_ADDRESS |"

# interface="$(/bin/ip route show default | awk '{print $5}')"
interface="$(/bin/ip route get "$(dig +short github.com | head -1)" | sed -rn 's|.*dev\s+(\S+)\s+src.*$|\1|p')"
macaddress="$(/bin/ip link show "${interface}" | sed -rn 's|.*ether ([0-9a-fA-F:]{17}).*$|\1|p' | tr '[a-z]' '[A-Z]')"
ipaddress=$(/bin/ip -4 a s "${interface}" | sed -nE 's/^[[:space:]]*inet[[:space:]]+([0-9]{1,3}(\.[0-9]{1,3}){3})\/[0-9]{1,2}.*/\1/p')
bandwidth=$(sudo /sbin/ethtool "${interface}"| sed -rn 's|\s*Speed:\s*(.+)$|\1|p')
case "${bandwidth}" in
  10000Mb/s ) bandwidth="\033[1;32m${bandwidth}\033[0m" ;;
esac
echo -e "| \033[1;36m$(hostname)\033[0m | ${bandwidth} | ${interface} | ${ipaddress} | ${macaddress} |"
# resolvectl status "${interface}"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh
