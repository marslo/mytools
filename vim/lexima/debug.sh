#!/usr/bin/env bash

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
cd "${HERE}" || exit 1

function execute() {
  local -r id="$1"
  local -r script="$2"
  local -r output="$3"

  echo "──────────────────────────────────────── ${id} ───────────────────────────────────────"
  test -f "${HERE}/${output}" && touch "${HERE}/${output}"
  nvim --headless -u NONE -S "${HERE}/${script}" -c 'qa!' 2>&1 | head
  cat "${HERE}/${output}"
  echo
}

function clean() {
  rm -f "${HERE}/output-"*.txt
}

function main() {
  clean
  execute 1 lx1.vim output-1.txt
  execute 2 lx2.vim output-2.txt
  execute 3 lx3.vim output-3.txt
  execute 4 lx4.vim output-4.txt
  execute 5 lx5.vim output-5.txt
  execute 6 lx6.vim output-6.txt
}

main "$@"
clean

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
