#!/usr/bin/env bash
# shellcheck disable=SC2021
#=============================================================================
#     FileName : checkNIC.sh
#       Author : marslo
#      Created : 2024-10-21 16:03:41
#   LastChange : 2025-09-18 02:03:33
#=============================================================================

set -euo pipefail

# echo -e "| HOSTNAME | BANDWIDTH | INTERFACE | IP_ADDRESS | MAC_ADDRESS |"

# interface="$(/bin/ip route get "$(dig +short github.com | head -1)" | sed -rn 's|.*dev\s+(\S+)\s+src.*$|\1|p')"
interface="$(/bin/ip route show default | awk '{print $5}')"
macaddress="$(/bin/ip link show "${interface}" | sed -rn 's|.*ether ([0-9a-fA-F:]{17}).*$|\1|p' | tr '[a-z]' '[A-Z]')"
ipaddress=$(/bin/ip a s "${interface}" | sed -rn 's|.*inet ([0-9\.]{7,15})/[0-9]{2} brd.*$|\1|p')
bandwidth=$(sudo /sbin/ethtool "${interface}"| sed -rn 's|\s*Speed:\s*(.+)$|\1|p')
echo -e "| \033[1;32m$(hostname)\033[0m | ${bandwidth} | ${interface} | ${ipaddress} | ${macaddress} |"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh
