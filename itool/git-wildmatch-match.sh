#!/usr/bin/env bash
# =============================================================================
#      FileName : git-wildmatch-match.sh
#        Author : marslo
#       Created : 2026-08-07 15:53:36
#    LastChange : 2026-08-07 16:52:56
# =============================================================================
# ──────────────────────────────────────────────── result ────────────────────────────────────────────────────
# PATTERN                      https?://      git@..:        git@-marslo:   ssh://git@     ssh://git@-marslo:
# *github.com?marslo/**                         Y
# **/marslo/**                   Y                                            Y              Y
# **:marslo/**                                  Y              Y
# **/*github*.com/marslo/**      Y                                            Y              Y
# *github*.com?marslo/**                        Y              Y
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────

set -euo pipefail

declare -a GIT=( /opt/homebrew/bin/git )
declare -a COLS=( 'https?://' 'git@..:' 'git@-marslo:' 'ssh://git@' 'ssh://git@-marslo:' )
declare -a URLS=(
  'https://github.com/marslo/x.git'
  'git@github.com:marslo/x.git'
  'git@github-marslo.com:marslo/x.git'
  'ssh://git@github.com/marslo/x.git'
  'ssh://git@github-marslo.com/marslo/x.git'
)
declare -a PATS=(
  '*github.com?marslo/**'
  '**/marslo/**'
  '**:marslo/**'
  '**/*github*.com/marslo/**'
  '*github*.com?marslo/**'
)

function match() {
  local pat="${1}" url="${2}" H TMP r
  H="$( mktemp -d )"; TMP="$( mktemp -d )"
  printf '[user]\n  email=NO\n[includeIf "hasconfig:remote.*.url:%s"]\n  path=%s/h\n' "${pat}" "${H}" > "${H}/gc"
  printf '[user]\n  email=YES\n' > "${H}/h"
  ( cd "${TMP}"; "${GIT[@]}" init -q; "${GIT[@]}" remote add origin "${url}"
    r="$( GIT_CONFIG_GLOBAL="${H}/gc" GIT_CONFIG_SYSTEM=/dev/null "${GIT[@]}" config user.email )"
    test 'YES' = "${r}" && echo 'Y' || echo ' ' )
  rm -rf "${H}" "${TMP}"
}

# header + data share ONE format:  %-28s  then  ' %-14s' per column
printf '%-28s' 'PATTERN'; printf ' %-14s' "${COLS[@]}"; echo
for p in "${PATS[@]}"; do
  printf '%-30s' "${p}"
  for u in "${URLS[@]}"; do printf ' %-14s' "$( match "${p}" "${u}" )"; done
  echo
done

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
