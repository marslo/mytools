#!/usr/bin/env bash
# =============================================================================
#      FileName : getVersion.sh
#        Author : marslo
#       Created : 2025-12-15 15:00:49
#    LastChange : 2026-08-18 16:43:30
# =============================================================================

set -euo pipefail

declare appsDirs=( "/Applications" "$HOME/Applications" )
function hr() { local cols; cols="$(tput cols 2>/dev/null || echo 80)"; printf '%*s\n' "${cols}" '' | tr ' ' '-'; }

{
  printf '#\tAPP\tVERSION\tBUILD\tBUNDLEID\tONLINE_VERSION\n';

  declare i=0
  for dir in "${appsDirs[@]}"; do
    test -d "${dir}" || continue

    while IFS= read -r -d '' app; do
      plist="${app}/Contents/Info.plist"
      name="$( /usr/bin/basename "${app}" .app )"

      declare local=''
      declare build=''
      declare bundleId=''

      if test -f "${plist}"; then
        local="$( /usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${plist}" 2>/dev/null || true )"
        build="$( /usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "${plist}" 2>/dev/null || true )"
        bundleId="$( /usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "${plist}" 2>/dev/null || true )"
        online="$( bash ./appStoreVersion.sh "${bundleId}" || true )"
      fi

      # fallback: Spotlight metadata
      if test -z "${local}"; then
        local="$( /usr/bin/mdls -name kMDItemVersion -raw "${app}" 2>/dev/null || true )"
        test "${local}" == "(null)" && local=''
      fi

      [[ "${online}" != "${local}" ]] && online="$(tput setaf 202)${online}$(tput sgr0)"

      (( ++i ))
      printf '%02d\t%s\t%s\t%s\t%s\t%b\n' "${i}" "${name}" "${local}" "${build}" "${bundleId}" "${online}"
    done < <( /usr/bin/find "${dir}" -maxdepth 1 -type d -name '*.app' -print0 | /usr/bin/sort -z )
  done
} | /usr/bin/column -t -s $'\t'

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
