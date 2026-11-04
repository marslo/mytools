#!/usr/bin/env bash
# =============================================================================
#      FileName : brewfile.sh
#        Author : marslo
#       Created : 2026-02-26 11:34:29
#    LastChange : 2026-11-03 19:46:46
# =============================================================================

set -euo pipefail

[[ 'iMarsloPro' = "$(hostname -f)" ]] && filename="brewfile.$(hostname -f)" || filename='brewfile'

if brew bundle dump --file="${filename}.new"; then
  test -f "./${filename}" && rm -vf "./${filename}"
  mv -v "./${filename}.new" "./${filename}"
fi

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
