#!/usr/bin/env bash
set -euo pipefail

export PATH=/usr/sbin:/usr/bin:/sbin:/bin
umask 0002

declare BASE="/ftp/release"
declare USER="ftpuser"
declare GROUP="ftpuser"
declare LOGTAG="ftp-perm-fixer"
declare LOGFILE="/var/log/${LOGTAG}.log"

function log() {
  local msg="$1"
  logger -t "${LOGTAG}" "$msg"
  echo "$(date '+%F %T') [${LOGTAG}] ${msg}" >> "${LOGFILE}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base ) BASE="$2"; shift 2 ;;
    *      ) echo -e "\033[31mERROR: Unknown option '$1'\033[0m" >&2; exit 1;
  esac
done

# preventing concurrency
[[ -d /run ]] || mkdir -p /run
exec 9>/run/${LOGTAG}.lock
flock -n 9 || { log "another run in progress"; exit 0; }

[[ -d "${BASE}" ]] || { log "${BASE} not found"; exit 1; }

log "start fixing ownership/permissions under ${BASE}"

# 1. fix owership
find "${BASE}" -xdev \( \! -user "${USER}" -o \! -group "${GROUP}" \) -print0 \
  | xargs -0 -r chown "${USER}:${GROUP}"

# 2. fix dir - 2775
find "${BASE}" -xdev -type d -not -perm -2775 -print0 \
  | xargs -0 -r chmod 2775

# 3. fix file - 0664
find "${BASE}" -xdev -type f -not -perm -0664 -print0 \
  | xargs -0 -r chmod 0664

# 4. fix base dir
chown "${USER}:${GROUP}" "${BASE}"
chmod 2775 "${BASE}"

log "finished fixing ${BASE}"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
