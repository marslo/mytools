#!/usr/bin/env bash
# shellcheck disable=SC2029
#=============================================================================
#     FileName : checkOS.sh
#       Author : marslo
#      Created : 2024-06-11 14:15:47
#   LastChange : 2025-09-18 02:01:09
#=============================================================================

set -euo pipefail

echo -e "\033[1;32m>> OS:\033[0m"
awk -F= '/^PRETTY_NAME=/ { gsub(/"/, "", $2); print $2 }' /etc/os-release
uname -a

echo -e "\033[1;32m>> SYSTEM INFO:\033[0m"
sudo dmidecode | grep -A5 '^System Information'

echo -e "\033[1;32m>> NIC:\033[0m"
# interface="$(/bin/ip route get "$(dig +short github.com | head -1)" | sed -rn 's|.*dev\s+(\S+)\s+src.*$|\1|p')"
interface=$(/bin/ip route show default | awk '{print $5}')
macaddress=$(/bin/ip link show "${interface}" | sed -rn 's|.*ether ([0-9a-fA-F:]{17}).*$|\1|p' | tr '[:lower:]' '[:upper:]')
bandwidth=$(sudo /sbin/ethtool "${interface}" | sed -rn 's|\s*Speed:\s*(.+)$|\1|p')
echo -e "• interface: ${interface}\n• mac address: ${macaddress}\n• bandwidth: ${bandwidth}"

echo -en "\033[1;32m>> MEMORY OVERALL:\033[0m "
sudo lshw -short | grep --color=never 'System Memory' | sed -E 's/.*\s([0-9]+[A-Za-z]+) System Memory/\1/'
sudo dmidecode -t memory | awk -v RS="" '
/^Handle [^\n]*\nMemory Device/ {
  size=""; unit=""; type=""; speed="";

  if (match($0, /Size:[[:space:]]+([0-9]+)[[:space:]]+(GB|MB)/, m)) {
    size=m[1]; unit=m[2];
  } else next;

  if (match($0, /Type:[[:space:]]+(DDR[0-9]+)/, t)) type=t[1]; else next;
  if (match($0, /Speed:[[:space:]]+([0-9]+)[[:space:]]+MT\/s/, s)) {
    sp=s[1];
  } else if (match($0, /Configured Memory Speed:[[:space:]]+([0-9]+)[[:space:]]+MT\/s/, s2)) {
    sp=s2[1];
  } else sp="";

  szGB = (unit=="MB") ? int(size/1024) : size;

  if (type != "" && szGB > 0) {
    key = szGB "GB|" type "|" sp;
    cnt[key]++; total += szGB;
  }
}
END {
  for (k in cnt) {
    split(k, a, /\|/); # a[1]=sizeGB, a[2]=type, a[3]=speed
    printf "• %dx%s %s", cnt[k], a[1], a[2];
    if (a[3] != "") printf " @ %s MT/s", a[3];
    print "";
  }
}'

echo -e "\033[1;32m>> MEMORY USAGE:\033[0m"
free -h

# echo -e "\033[1;32m>> memory details:\033[0m"
# sudo dmidecode -t memory | grep -E '(^Memory Device|^\s+(Size:|Type:|Type Detail:|Serial Number:|Part Number:|Memory Technology:|Configured Memory Speed:|Manufacturer))' --color=never | grep -v -E 'Not Specified|No Module|Unknow|None|Memory Technology: <OUT OF SPEC>'

echo -e "\033[1;32m>> CPU INFO:\033[0m"
sudo lscpu |
  grep --color=none -E '^(Thread|Core|Socket|CPU\(|NUMA\ node\(|Model\ name|CPU.+MHz|BogoMIPS)' |
  awk '{print "• ", $0}'
echo -ne "\033[1;32m>> CORES:\033[0m "
getconf _NPROCESSORS_ONLN

echo -ne "\033[1;32m>> SERIAL NUMBER:\033[0m "
sudo dmidecode -s system-serial-number

echo -ne "\033[1;32m>> RAID INFO:\033[0m "
RAID_SCAN=$(sudo mdadm --detail --scan)
if [[ -z "$RAID_SCAN" ]]; then
  echo -e "\033[38;5;245;3mNO RAID\033[0m"
else
  RAID_DEVICES=$(echo "${RAID_SCAN}" | awk '/^ARRAY/ {print $2}')
  declare -a RAID_TYPES=()
  for dev in ${RAID_DEVICES}; do
    level=$(sudo mdadm --detail "${dev}" 2>/dev/null | awk -F ': ' '/Raid Level/ {print toupper(\$2)}')
    [[ -n "${level}" ]] && RAID_TYPES+=("$level")
  done
  if [[ ${#RAID_TYPES[@]} -eq 0 ]]; then
    echo -e "\033[38;5;245;3mUNKNOWN RAID\033[0m"
  else
    UNIQUE_RAID_TYPES=$(printf "%s\n" "${RAID_TYPES[@]}" | sort -u | paste -sd ',')
    echo "${UNIQUE_RAID_TYPES}"
  fi
fi
type -P smartctl >/dev/null 2>&1 && { sudo smartctl --scan | awk '{print "• ", $0}'; } || echo ".. install smartctl via \`sudo apt install -y smartmontools\` first"

echo -e "\033[38;5;241;3m.. ROTA: 0 - SSD; 1 - HDD; 7 - CD/DVD\033[0m"
echo -en "\033[1;32m>> SSD/HHD INFO:\033[0m "
lsblk -d -e 7 -o NAME,ROTA,DISC-MAX,MODEL,TYPE | awk '
NR == 1 {
  line = $0
  sub(/[[:space:]]+TYPE$/, "", line)
  header = "  " line
  next
}
$5 != "disk" { next }

{
  line = $0
  sub(/[[:space:]]+disk$/, "", line)

  lines[++i] = "• " line
  if ($2 == 1) hasHHD = 1
  if ($2 == 0) hasSSD = 1
}
END {
  if (hasHHD && hasSSD) print "MIXED"
  else if (hasHHD)      print "HDD"
  else if (hasSSD)      print "SSD"

  print header
  for (j = 1; j <= i; ++j) print lines[j]
}'

echo -en "\033[1;32m>> DISK INFO:\033[0m "
sudo fdisk -l | awk '
/^Disk \/dev\/(sd[a-z]|nvme[0-9]+n[0-9]+|vd[a-z]|xvd[a-z]|hd[a-z]|mmcblk[0-9]+):/ {
  device = $2
  size   = $3
  unit   = $4

  sub(/:$/, "", device)
  sub(/,?$/, "", unit)

  if      (unit ~ /^GiB$/) gib = size + 0
  else if (unit ~ /^MiB$/) gib = size / 1024
  else if (unit ~ /^TiB$/) gib = size * 1024
  else if (unit ~ /^GB$/)  gib = size * 0.931322575
  else if (unit ~ /^MB$/)  gib = size * 0.000931322575
  else if (unit ~ /^TB$/)  gib = size * 931.322575
  else                      gib = 0

  total += gib
  lines[++i] = sprintf("• %-14s : %.2f %s", device, size, unit)
}
END {
  printf "%.0f GiB\n", total
  for (j = 1; j <= i; j++) print lines[j]
}'
# sudo fdisk -l \
#   | awk '/^Disk \/dev\/nvme/ {print $2, $3, $4}' \
#   | sed 's/,$//'

echo -en "\033[1;32m>> DISK LVM INFO:\033[0m "
lsblk -b -o TYPE,SIZE | awk '
BEGIN  { flag = 0; size = 0;   }
/^lvm/ { flag = 1; size += $2; }
END    {
  print ( flag ? "true" : "false" )
  printf "• LVM : %.0f GiB\n", size / 1024 / 1024 / 1024
  if (flag) {
    # system("sudo vgs")
    while (( "sudo vgs --noheadings --units g -o vg_free,vg_size" | getline ) > 0 ) {
      gsub(/[ \t]+/, " "); gsub(/^ /, "")
      split($0, arr, " ")
      free = arr[1]; total = arr[2]
      gsub(/[gG]$/, "", free)
      gsub(/[gG]$/, "", total)
      printf "• VGS : %.0fGB/%.0fGB\n", total - free, total
    }
  }
}'

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh
