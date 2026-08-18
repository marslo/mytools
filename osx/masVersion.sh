#!/usr/bin/env bash
# =============================================================================
#      FileName : masVersion.sh
#        Author : marslo
#       Created : 2026-08-18 16:11:44
#    LastChange : 2026-08-18 16:46:18
#   Description : print the [m]ac [a]pp [s]tore version for a bundle id
# =============================================================================

set -euo pipefail

# usage: masVersion <bundleId> [country ...]   (default storefronts: cn us)
function masVersion() {
  local bundleId="${1:?usage: masVersion <bundleId> [country...]}"; shift
  local -a stores=( "${@}" )
  test ${#stores[@]} -eq 0 && stores=( cn us )

  local cc ver
  for cc in "${stores[@]}"; do
    ver="$( command curl -fsG 'https://itunes.apple.com/lookup' \
                    --data-urlencode "bundleId=${bundleId}" \
                    --data-urlencode "country=${cc}" |
            plutil -extract results.0.version raw -o - - 2>/dev/null )"
    test -n "${ver}" && { echo "${ver}"; return 0; }
  done
  echo "not found on App Store: ${bundleId}" >&2
  return 1
}

masVersion "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
