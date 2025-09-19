#!/usr/bin/env bash
# shellcheck disable=SC2029
#=============================================================================
#     FileName : checkOS.sh
#       Author : marslo
#      Created : 2024-06-11 14:15:47
#   LastChange : 2025-09-19 01:54:16
#=============================================================================

set -euo pipefail

function checkRAID() {
  # 1) Find the top-level block device for '/', fallback to /dev/sda
  local rootSrc pk dev kname
  rootSrc="$(findmnt -no SOURCE / 2>/dev/null || true)"
  if [[ -n "${rootSrc}" ]]; then
    rootSrc="$(readlink -f "${rootSrc}")"
    pk="$(lsblk -no PKNAME "${rootSrc}" 2>/dev/null || true)"
    dev="/dev/${pk:-$(basename "${rootSrc}")}"
    # If it's LVM/mapper, resolve to the physical block device
    [[ "${dev}" =~ ^/dev/mapper/ ]] && pk="$(lsblk -no PKNAME "${dev}" 2>/dev/null)" && [[ -n "${pk}" ]] && dev="/dev/${pk}"
  else
    dev="/dev/sda"
  fi
  kname="$(basename "$(readlink -f "${dev}")" 2>/dev/null)"

  # 2) Software RAID (mdadm): if present, read level from /proc/mdstat (e.g., raid1→RAID1)
  if awk '/^md[0-9]+/ {found=1} END{exit !found}' /proc/mdstat 2>/dev/null; then
    awk '/^md[0-9]+/ {
           for (i=1;i<=NF;i++) if ($i ~ /^raid[0-9]+$/) { print toupper($i); exit }
         }' /proc/mdstat
    return
  fi

  # 2.5) NVMe JBOD fast path:
  #      If no mdadm, no RAID controller in lspci, and >=2 NVMe disks exist → "none (NVMe JBOD)"
  local hasRaidCtrl="no"
  if lspci | grep -qiE 'raid|megaraid|perc|smart array|lsi|broadcom'; then
    hasRaidCtrl="yes"
  fi
  # Count NVMe disks (TYPE=disk; names like nvme0n1, nvme1n1…)
  local nvmeCount=0
  nvmeCount="$(lsblk -dn -o NAME,TYPE 2>/dev/null | awk '$2=="disk" && $1 ~ /^nvme/ {c++} END{print c+0}')"
  if [[ "${hasRaidCtrl}" == "no" ]] && (( nvmeCount >= 2 )); then
    echo "none (NVMe JBOD)"
    return
  fi

  # 3) Get logical device size in bytes (with fallbacks)
  local logical_b=0 sec cnt
  logical_b="$(blockdev --getsize64 "${dev}" 2>/dev/null || echo 0)"
  if (( logical_b == 0 )) && [[ -e "/sys/block/${kname}/size" ]]; then
    cnt="$(cat "/sys/block/${kname}/size" 2>/dev/null || echo 0)"
    sec="$(cat "/sys/block/${kname}/queue/logical_block_size" 2>/dev/null || echo 512)"
    logical_b=$(( cnt * sec ))
  fi
  if (( logical_b == 0 )); then
    logical_b="$(lsblk -b -dn -o SIZE "${dev}" 2>/dev/null || echo 0)"
  fi

  # 4) Enumerate physical drives via smartctl(megaraid) to infer HW RAID level
  local -a phys_b=()
  local i cap cap_b
  for i in {0..63}; do
    if sudo smartctl -i -d "megaraid,${i}" "${dev}" &>/dev/null \
       || smartctl -i -d "megaraid,${i}" "${dev}" &>/dev/null; then
      cap="$(sudo smartctl -i -d "megaraid,${i}" "${dev}" 2>/dev/null || smartctl -i -d "megaraid,${i}" "${dev}" 2>/dev/null)"

      # First try bracketed value like "[960 GB]" or "[894 GiB]"
      cap_b="$(awk -F'[][]' '/User Capacity/ {gsub(/^[ \t]+|[ \t]+$/, "", $2); print $2; exit}' <<<"${cap}")"
      if [[ -n "${cap_b}" ]]; then
        case "${cap_b}" in
          *GiB ) cap_b="${cap_b% GiB}"; cap_b="$(awk -v g="${cap_b}" 'BEGIN{printf "%.0f", g*1024*1024*1024}')" ;;
          *GB  ) cap_b="${cap_b% GB}";  cap_b="$(awk -v g="${cap_b}" 'BEGIN{printf "%.0f", g*1000*1000*1000}')" ;;
          *    ) cap_b="" ;;
        esac
      fi
      # Fallback: parse "xxxx bytes"
      if [[ -z "${cap_b}" ]]; then
        cap_b="$(awk ' /User Capacity/ && match($0,/([0-9][0-9,]*)[ ]+bytes/,m) {gsub(/,/, "", m[1]); print m[1]; exit}' <<<"${cap}")"
      fi

      [[ -n "${cap_b}" ]] && phys_b+=( "${cap_b}" )
    fi
  done

  # 5) Infer common RAID levels via logical vs physical capacities; otherwise return NO RAID
  local n="${#phys_b[@]}"
  # No mdadm and no megaraid PDs readable ⇒ treat as no RAID
  if (( n == 0 )); then echo "NO RAID"; return; fi

  # Use the first PD as baseline; tolerance = max(5% logical, 5% physical, 8GiB)
  local p="${phys_b[0]}"
  local tol=$(( logical_b/20 ))
  local tol_p=$(( p/20 ))
  (( tol_p > tol )) && tol="${tol_p}"
  local eight=$(( 8*1024*1024*1024 ))
  (( eight > tol )) && tol="${eight}"

  # Convenience variables
  local np=$(( n * p ))               # n × single disk
  local n_1p=$(( (n - 1) * p ))       # (n-1) × single disk
  local n_2p=$(( (n - 2) * p ))       # (n-2) × single disk
  local n_halfp=$(( (n / 2) * p ))    # (n/2) × single disk（RAID10）

  # Match common RAID capacity patterns
  if   (( n == 1 )); then
    echo "none"                       # Single disk (no RAID)
  elif (( n == 2 )) && (( logical_b >= p - tol && logical_b <= p + tol )); then
    echo "RAID1"                      # 2 disks, capacity ≈ one disk
  elif (( logical_b >= np - tol && logical_b <= np + tol )); then
    echo "RAID0"                      # Capacity ≈ n × single disk
  elif (( n >= 3 )) && (( logical_b >= n_1p - tol && logical_b <= n_1p + tol )); then
    echo "RAID5"                      # Capacity ≈ (n-1) × single disk
  elif (( n >= 4 )) && (( logical_b >= n_2p - tol && logical_b <= n_2p + tol )); then
    echo "RAID6"                      # Capacity ≈ (n-2) × single disk
  elif (( n % 2 == 0 )) && (( logical_b >= n_halfp - tol && logical_b <= n_halfp + tol )); then
    echo "RAID10"                     # even n, capacity ≈ (n/2) × disk
  else
    echo "NO RAID"                    # uncommon layout or cannot infer
  fi
}

# -- main -- #
echo -e "\033[1;32m>> OS:\033[0m"
awk -F= '/^PRETTY_NAME=/ { gsub(/"/, "", $2); print $2 }' /etc/os-release
uname -a

echo -e "\033[1;32m>> SYSTEM INFO:\033[0m"
sudo dmidecode | grep -A5 '^System Information'

echo -e "\033[1;32m>> NIC:\033[0m"
interface=$(/bin/ip route show default | awk '{print $5}')
macaddress=$(/bin/ip link show "${interface}" | sed -rn 's|.*ether ([0-9a-fA-F:]{17}).*$|\1|p' | tr '[:lower:]' '[:upper:]')
bandwidth=$(sudo /sbin/ethtool "${interface}" | sed -rn 's|\s*Speed:\s*(.+)$|\1|p')
case "${bandwidth}" in
  10000Mb/s ) bandwidth="\033[1;36m${bandwidth}\033[0m" ;;
esac
echo -e "• interface: ${interface}\n• mac address: ${macaddress}\n• bandwidth: ${bandwidth}"

echo -en "\033[1;32m>> MEMORY OVERALL:\033[0m "
sudo lshw -short | grep --color=never 'System Memory' | sed -E 's/.*\s([0-9]+[A-Za-z]+) System Memory/\1/'
sudo dmidecode -t memory | awk -v RS="" '
/^Handle [^\n]*\nMemory Device/ {
  size=""; unit=""; type=""; sp="";
  # Size: 16384 MB
  if (match($0, /Size:[[:space:]]+[0-9]+[[:space:]]+(GB|MB)/)) {
    seg = substr($0, RSTART, RLENGTH);
    sub(/^Size:[[:space:]]+/, "", seg);
    n = split(seg, f, /[[:space:]]+/);
    size = f[1]; unit = f[2];
  } else next;
  # Type: DDR4
  if (match($0, /Type:[[:space:]]+DDR[0-9]+/)) {
    seg = substr($0, RSTART, RLENGTH);
    sub(/^Type:[[:space:]]+/, "", seg);
    type = seg;
  } else next;
  # Speed or Configured Memory Speed
  if (match($0, /Speed:[[:space:]]+[0-9]+[[:space:]]+MT\/s/)) {
    seg = substr($0, RSTART, RLENGTH);
    gsub(/[^0-9]/, "", seg); sp = seg;
  } else if (match($0, /Configured Memory Speed:[[:space:]]+[0-9]+[[:space:]]+MT\/s/)) {
    seg = substr($0, RSTART, RLENGTH);
    gsub(/[^0-9]/, "", seg); sp = seg;
  }
  # to GB
  szGB = (unit=="MB") ? int(size/1024) : size+0;
  if (type != "" && szGB > 0) {
    key = szGB "GB|" type "|" sp;
    cnt[key]++; total += szGB;
  }
} END {
  for (k in cnt) {
    split(k, a, /\|/); # a[1]=sizeGB, a[2]=type, a[3]=speed
    printf "• %dx%s %s", cnt[k], a[1], a[2];
    if (a[3] != "") printf " @ %s MT/s", a[3];
    print "";
  }
  if (total>0) printf "Total: %d GB\n", total;
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
type -P mdadm >/dev/null 2>&1 || { echo -e "\n.. install mdadm via \`sudo apt install -y mdadm\` first"; exit 0; }
printf "\033[38;5;245;3m%s\033[0m\n" "$(checkRAID)"
type -P smartctl >/dev/null 2>&1 && { sudo smartctl --scan | awk '{print "• ", $0}'; } || echo ".. install smartctl via \`sudo apt install -y smartmontools\` first"

echo -e "\033[38;5;241;3m# ROTA: 0 - SSD; 1 - HDD; 7 - CD/DVD\033[0m"
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
  else                     gib = 0

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

# deprecated
function raidScan(){
  type -P mdadm >/dev/null 2>&1 || { echo -e "\n.. install mdadm via \`sudo apt install -y mdadm\` first"; exit 0; }
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
}

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh
