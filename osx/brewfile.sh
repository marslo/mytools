#!/usr/bin/env bash

set -euo pipefail

[[ 'iMarsloPro' = "$(hostname -f)" ]] && filename="brewfile.$(hostname -f)" || filename='brewfile'

if brew bundle dump --file="${filename}.new" --describe; then
  test -f "./${filename}" && rm -vf "./${filename}"
  mv -v "./${filename}.new" "./${filename}"
fi

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
