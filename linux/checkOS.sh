#!/usr/bin/env bash
# shellcheck disable=SC2029
#=============================================================================
#     FileName : checkOS.sh
#       Author : marslo
#      Created : 2024-06-11 14:15:47
#   LastChange : 2026-08-10 19:36:46
#=============================================================================

set -euo pipefail

# system-wide DDR generation hint, populated by detectDDR() in main
DDR_HINT=''
DDR_SRC=''

# ---------- helpers ---------- #

# print a green section header; with '-n' keep the cursor on the same line
function header() {
  if test '-n' = "${1:-}"; then
    shift
    printf '\033[1;32m>> %s:\033[0m ' "${1}"
  else
    printf '\033[1;32m>> %s:\033[0m\n' "${1}"
  fi
}

# ---------- probes ---------- #

# infer HW/SW RAID level for the root block device; echoes e.g. RAID1 / none / NO RAID
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

# detect system-wide DDR generation via a cascade of sources (most -> least reliable)
# echoes two tab-separated fields: "<DDRx>\t<source>"; both empty when undetermined
function detectDDR() {
  local t='' f

  # 1) kernel EDAC: memory-controller reported; e.g. Registered-DDR4, Unbuffered-DDR3, LPDDR4
  for f in /sys/devices/system/edac/mc/mc*/dimm*/dimm_mem_type \
           /sys/devices/system/edac/mc/mc*/csrow*/mem_type; do
    test -r "${f}" || continue
    t="$( command grep -hoiE 'LPDDR[0-9]+|DDR[0-9]+' "${f}" 2>/dev/null | head -1 | tr '[:lower:]' '[:upper:]' || true )"
    test -n "${t}" && { printf '%s\tedac\n' "${t}"; return 0; }
  done

  # 2) SPD via decode-dimms (i2c-tools): ground truth read from the module SPD
  if type -P decode-dimms >/dev/null 2>&1; then
    t="$( decode-dimms 2>/dev/null | sed -rn 's/.*Fundamental Memory type[[:space:]:]+(LP)?DDR([0-9]*).*/\1DDR\2/p' | head -1 | tr '[:lower:]' '[:upper:]' || true )"
    test -n "${t}" && { printf '%s\tspd\n' "${t}"; return 0; }
  fi

  # 3) dmidecode Type field: mode across populated modules, only when a real DDR name
  if type -P dmidecode >/dev/null 2>&1; then
    t="$( sudo dmidecode -t memory 2>/dev/null | command grep -oiE 'LPDDR[0-9]+|DDR[0-9]+' | sort | uniq -c | sort -rn | awk 'NR==1{print toupper($2)}' || true )"
    test -n "${t}" && { printf '%s\tdmi\n' "${t}"; return 0; }
  fi

  printf '\t\n'   # undetermined -> per-module voltage/speed heuristic in awk
}

# ---------- sections (logic only; headers printed by main) ---------- #

function osInfo() {
  awk -F= '/^PRETTY_NAME=/ { gsub(/"/, "", $2); print $2 }' /etc/os-release
  uname -a
}

function sysInfo() {
  sudo dmidecode | grep -A5 '^System Information'
}

function nicInfo() {
  local interface macaddress bandwidth
  interface="$(/bin/ip route show default | awk '{print $5}')"
  macaddress="$(/bin/ip link show "${interface}" | sed -rn 's|.*ether ([0-9a-fA-F:]{17}).*$|\1|p' | tr '[:lower:]' '[:upper:]')"
  bandwidth="$(sudo /sbin/ethtool "${interface}" | sed -rn 's|\s*Speed:\s*(.+)$|\1|p')"
  case "${bandwidth}" in
    10000Mb/s ) bandwidth="\033[1;36m${bandwidth}\033[0m" ;;
  esac
  echo -e "• interface: ${interface}\n• mac address: ${macaddress}\n• bandwidth: ${bandwidth}"
}

function memOverall() {
  sudo lshw -short | grep --color=never 'System Memory' | sed -E 's/.*\s([0-9]+[A-Za-z]+) System Memory/\1/'
  sudo dmidecode -t memory | awk -v RS="" -v ddr="${DDR_HINT}" -v ddrsrc="${DDR_SRC}" '
/^Handle [^\n]*\nMemory Device/ {
  if (match($0, /Size: No Module Installed/)) {
    empty_slots++;
    next;
  }

  # Size and Unit
  if (match($0, /Size: [0-9]+ [MG]B/)) {
    s_part = substr($0, RSTART, RLENGTH);
    split(s_part, f, " ");
    size = f[2]; unit = f[3];
  } else next;

  # Type
  type = "Unknown";
  if (match($0, /Type: [^\n]+/)) {
    type = substr($0, RSTART+6, RLENGTH-6);
    gsub(/[[:space:]]+$/, "", type);
  }

  # Speed
  sp = "";
  if (match($0, /Configured Memory Speed: [0-9]+/)) {
    m = substr($0, RSTART, RLENGTH);
    split(m, f, ": "); sp = f[2];
  } else if (match($0, /Speed: [0-9]+/)) {
    m = substr($0, RSTART, RLENGTH);
    split(m, f, ": "); sp = f[2];
  }

  # voltage (for predicted)
  volt = 0;
  if (match($0, /Configured Voltage: [0-9.]+/)) {
    m = substr($0, RSTART, RLENGTH);
    split(m, f, ": "); volt = f[2];
  }

  # resolve DDR generation: trust valid BIOS Type, else external hint, else heuristic
  if (type !~ /^(LP)?DDR[0-9]/) {
    if      (ddr != "")                                type = ddr " (" ddrsrc ")";
    else if (volt == 1.1  || sp >= 4800)               type = "DDR5 (guess)";
    else if (volt == 1.2  || (sp >= 2133 && sp <= 3200)) type = "DDR4 (guess)";
    else if (volt >= 1.35 || (sp >= 800 && sp < 2133)) type = "DDR3 (guess)";
    else if (volt == 1.8  || (sp >= 400 && sp < 800))  type = "DDR2 (guess)";
  }

  # summary
  szGB = (unit == "MB") ? int(size/1024) : size+0;
  if (szGB > 0) {
    key = szGB "GB|" type "|" sp;
    cnt[key]++; total += szGB;
  }
} END {
  for (k in cnt) {
    split(k, a, "|");  # a[1]=sizeGB, a[2]=type, a[3]=speed
    printf "• \033[1;35m%dx%s %s\033[0m", cnt[k], a[1], a[2];
    if (a[3] != "") printf "\033[1;35m @ %s MT/s\033[0m", a[3];
    print "";
  }

  # empty slot summary
  if (empty_slots > 0) {
    printf "• \033[2;3;37m%dx<Empty Slots>\033[0m\n", empty_slots;
  }
  if (total > 0) printf "• Total: %d GB\n", total;
}'
}

function memUsage() {
  free -h
}

function memDetails() {
  sudo dmidecode -t memory | awk -v RS="" -v FS="\n" -v ddr="${DDR_HINT}" -v ddrsrc="${DDR_SRC}" '
/^Handle [^\n]*\nMemory Device/ {
  if (/Size: No Module Installed/ || /Size: Not Specified/) next;

  delete info
  for( i=1; i<=NF; i++ ) {
    if (idx = index($i, ":")) {
      k = substr($i, 1, idx-1); sub(/^[ \t]+/, "", k)
      v = substr($i, idx+1);    sub(/^[ \t]+/, "", v)
      info[k] = v
    }
  }

  # resolve DDR generation: trust valid BIOS Type, else external hint, else heuristic
  memType = info["Type"]
  if ( memType !~ /^(LP)?DDR[0-9]/ ) {
    volt = info["Configured Voltage"] + 0
    sp   = info["Configured Memory Speed"] + 0
    if ( sp == 0 ) sp = info["Speed"] + 0
    if      ( ddr != "" )                                 memType = ddr " (" ddrsrc ")"
    else if ( volt == 1.1  || sp >= 4800 )                memType = "DDR5 (guess)"
    else if ( volt == 1.2  || (sp >= 2133 && sp <= 3200) ) memType = "DDR4 (guess)"
    else if ( volt >= 1.35 || (sp >= 800 && sp < 2133) )  memType = "DDR3 (guess)"
    else if ( volt == 1.8  || (sp >= 400 && sp < 800) )   memType = "DDR2 (guess)"
  }

  # grouping items
  key = info["Size"] "|" memType "|" info["Type Detail"] "|" info["Memory Technology"] "|" info["Configured Memory Speed"] "|" info["Manufacturer"] "|" info["Part Number"]
  count[key]++

  # sn
  sn = info["Serial Number"]
  if ( sn != "" && sn != "Unknown" && sn != "Not Specified" ) {
    if ( sns[key] == "" ) sns[key] = sn
    else sns[key] = sns[key] ", " sn
  }
}
END {
  for ( k in count ) {
    split( k, f, "|" )
    print "•  Quantity         \t" count[k]
    print "•  Size             \t" f[1]
    print "•  Type             \t" f[2]
    print "•  Type Detail      \t" f[3]
    print "•  Memory Technology\t" f[4]
    print "•  Configured Speed \t" f[5]
    print "•  Manufacturer     \t" f[6]
    print "•  Part Number      \t" f[7]
    print "•  Serial Number(s) \t" (sns[k] ? sns[k] : "N/A")
  }
}'
  # sudo dmidecode -t memory | grep -E '(^Memory Device|^\s+(Size:|Type:|Type Detail:|Serial Number:|Part Number:|Memory Technology:|Configured Memory Speed:|Manufacturer))' --color=never | grep -v -E 'Not Specified|No Module|Unknow|None|Memory Technology: <OUT OF SPEC>'
}

function cpuInfo() {
  sudo lscpu |
    grep --color=none -E '^(Thread|Core|Socket|CPU\(|NUMA\ node\(|Model\ name|CPU.+MHz|BogoMIPS)' |
    awk '{print "• ", $0}'
}

function cores() {
  getconf _NPROCESSORS_ONLN
}

function serialNumber() {
  sudo dmidecode -s system-serial-number
}

function raidInfo() {
  if ! type -P mdadm >/dev/null 2>&1; then
    echo -e "\n.. install mdadm via \`sudo apt install -y mdadm\` first"
    return 0
  fi
  printf "\033[38;5;245;3m%s\033[0m\n" "$(checkRAID)"
  if ! type -P smartctl >/dev/null 2>&1; then
    echo -e "\033[2;3;37m.. install smartctl via \`sudo apt install -y smartmontools\` first ..\033[0m"
    sudo apt update -y && sudo apt install -y smartmontools
  fi
  if type -P smartctl >/dev/null 2>&1; then
    sudo smartctl --scan | awk '{print "• ", $0}'
  else
    echo -e "\033[0;3;32m.. smartctl not found, cannot scan for RAID devices ..\033[0m"
  fi
}

function storageType() {
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
    if ( $2 == 1 ) hasHHD = 1
    if ( $2 == 0 ) hasSSD = 1
  } END {
    if ( hasHHD && hasSSD ) print "MIXED"
    else if ( hasHHD )      print "HDD"
    else if ( hasSSD )      print "SSD"

    print header
    for ( j = 1; j <= i; ++j ) print lines[j]
  }
'
}

function diskInfo() {
  sudo fdisk -l | awk '
  /^Disk \/dev\/(sd[a-z]|nvme[0-9]+n[0-9]+|vd[a-z]|xvd[a-z]|hd[a-z]|mmcblk[0-9]+):/ {
    device = $2
    size   = $3
    unit   = $4

    sub( /:$/, "", device )
    sub( /,?$/, "", unit )

    if      ( unit ~ /^GiB$/ ) gib = size + 0
    else if ( unit ~ /^MiB$/ ) gib = size / 1024
    else if ( unit ~ /^TiB$/ ) gib = size * 1024
    else if ( unit ~ /^GB$/ )  gib = size * 0.931322575
    else if ( unit ~ /^MB$/ )  gib = size * 0.000931322575
    else if ( unit ~ /^TB$/ )  gib = size * 931.322575
    else                       gib = 0

    total += gib
    lines[++i] = sprintf("• %-14s : %.2f %s", device, size, unit)
  } END {
    printf "%.0f GiB\n", total
    for ( j = 1; j <= i; j++ ) print lines[j]
  }
'
  # sudo fdisk -l \
  #   | awk '/^Disk \/dev\/nvme/ {print $2, $3, $4}' \
  #   | sed 's/,$//'
}

function lvmInfo() {
  lsblk -b -o TYPE,SIZE | awk '
  BEGIN  { flag = 0; size = 0;   }
  /^lvm/ { flag = 1; size += $2; }
  END    {
    print ( flag ? "\033[1;36mtrue\033[0m" : "\033[1;31mfalse\033[0m" )
    printf "• LVM : %.0f GiB\n", size / 1024 / 1024 / 1024
    if ( flag ) {
      # system( "sudo vgs" )
      while ( ( "sudo vgs --noheadings --units g -o vg_free,vg_size" | getline ) > 0  ) {
        gsub( /[ \t]+/, " " ); gsub(/^ /, "")
        split( $0, arr, " " )
        free = arr[1]; total = arr[2]
        gsub( /[gG]$/, "", free  )
        gsub( /[gG]$/, "", total )
        printf "• VGS : %.0fGB/%.0fGB\n", total - free, total
      }
    }
  }
'
}

# ---------- deprecated ---------- #

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

# ───── groups (header + section, grouped bay selector flag) ──────────────────

function osGroup() {
  header 'OS'
  osInfo
  header 'SYSTEM INFO'
  sysInfo
}

function networkGroup() {
  header 'NIC'
  nicInfo
}

function memGroup() {
  # detect DDR generation once; shared by the memory sections
  IFS=$'\t' read -r DDR_HINT DDR_SRC < <(detectDDR)
  header -n 'MEMORY OVERALL'
  memOverall
  header 'MEMORY DETAILS'
  memDetails
  header 'MEMORY USAGE'
  memUsage
}

function cpuGroup() {
  header 'CPU INFO'
  cpuInfo
  header -n 'CORES'
  cores
  header -n 'SERIAL NUMBER'
  serialNumber
}

function diskGroup() {
  header -n 'RAID INFO'
  raidInfo
  echo -e "\033[38;5;241;3m# ROTA: 0 (SSD); 1 (HDD); 7 (CD/DVD)\033[0m"
  header -n 'SSD/HHD INFO'
  storageType
  header -n 'DISK INFO'
  diskInfo
  header -n 'DISK LVM INFO'
  lvmInfo
}

# ---------- main ---------- #

function usage() {
  cat <<'EOF'
Usage: checkOS.sh [OPTIONS]...

Show host hardware / OS summary. With no options, show everything.
Options may be combined, e.g. `checkOS.sh --mem --cpu`.

Options:
  --os, --system   OS release + DMI system information
  --network        NIC (interface, MAC, bandwidth)
  --mem            memory overall / details / usage (+ DDR detection)
  --cpu            CPU info / cores / serial number
  --disk           RAID / SSD-HDD / disk / LVM
  -h, --help       show this help and exit
EOF
}

function main() {
  local showOS=0 showNet=0 showMem=0 showCpu=0 showDisk=0 selected=0

  while (( $# )); do
    case "${1}" in
      --os | --system ) showOS=1;   selected=1 ;;
      --network        ) showNet=1;  selected=1 ;;
      --mem            ) showMem=1;  selected=1 ;;
      --cpu            ) showCpu=1;  selected=1 ;;
      --disk           ) showDisk=1; selected=1 ;;
      -h | --help      ) usage; return 0 ;;
      --               ) shift; break ;;
      -*               ) echo "checkOS.sh: unknown option '${1}'" >&2; usage >&2; return 2 ;;
      *                ) echo "checkOS.sh: unexpected argument '${1}'" >&2; usage >&2; return 2 ;;
    esac
    shift
  done

  # no selector -> show all
  if (( selected == 0 )); then
    showOS=1; showNet=1; showMem=1; showCpu=1; showDisk=1
  fi

  # fixed order reproduces the original full-output layout
  if (( showOS   )); then osGroup;      fi
  if (( showNet  )); then networkGroup; fi
  if (( showMem  )); then memGroup;     fi
  if (( showCpu  )); then cpuGroup;     fi
  if (( showDisk )); then diskGroup;    fi
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh
