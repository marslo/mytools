#!/usr/bin/env bash
# =============================================================================
#      FileName : xjar.sh
#        Author : marslo
#       Created : 2026-05-29 23:35:15
#    LastChange : 2026-05-30 01:09:10
# =============================================================================

set -euo pipefail

declare VERBOSE=false
declare -a CMD=( 'jar' )
declare -a FILES=()
declare USAGE="NAME
  $0 - extract files from JAR archives

USAGE
  \$ $0 [OPTIONS] FILE ...

OPTIONS
  -v          verbose output
  -h, --help   show this help message and exit

EXAMPLE
  \$ $0 -v foo.jar bar.jar baz.jar
"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -v          ) VERBOSE=true; shift ;;
    -h | --help ) echo -e "${USAGE}" >&2; exit 0 ;;
    -*          ) echo "ERROR: unknown option '$1'"; exit 1;;
    *           ) FILES+=( "$@" ); break ;;
  esac
done

[[ ${#FILES[@]} -eq 0 ]] && { echo "ERROR: no files specified" >&2; exit 1; }

"${VERBOSE}" && CMD+=( 'xvf' ) || CMD+=( 'xf' )
"${CMD[@]}" "${FILES[@]}"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
