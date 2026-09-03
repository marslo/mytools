#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 21:25:19
#    LastChange : 2026-09-03 02:06:49
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

# shellcheck disable=SC2155
declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r BIN_NAME='go'
declare VERSION="$( curl -fsSL --max-time 20 'https://go.dev/VERSION?m=text' | head -1 )"
test -n "${VERSION}" || { echo 'ERROR: FAILED to resolve version' >&2; exit 1; }
declare VERSION="${VERSION#"${BIN_NAME}"}"

case "$( uname -s )" in
  Linux  ) OS='linux'  ;;
  Darwin ) OS='macos'  ;;
  *      ) echo "ERROR: unsupported OS: $( uname -s )" >&2; exit 1 ;;
esac
case "$( uname -m )" in
  x86_64  | amd64 ) ARCH='amd64' ;;
  aarch64 | arm64 ) ARCH='arm64' ;;
  *               ) echo "ERROR: unsupported arch: $( uname -m )" >&2; exit 1 ;;
esac
declare -r PACKAGE_NAME="${BIN_NAME}${VERSION}.${OS}-${ARCH}.tar.gz"
declare -r PACKAGE="${HERE}/${PACKAGE_NAME}"
declare -r FOLDER_NAME="${PACKAGE_NAME%.tar.gz}"

# shellcheck disable=SC2015
function clean() {
  test -f "${PACKAGE}"     && rm -f "${PACKAGE}"      || :
  test -d "${FOLDER_NAME}" && rm -rf "${FOLDER_NAME}" || :
}

function setup() {
  curl -fsSL --max-time 240 -o "${PACKAGE}" "https://go.dev/dl/${PACKAGE_NAME}" || { echo "ERROR: FAILED to download ${PACKAGE_NAME}" >&2; exit 1; }
  printf "==> size: %s\n" "$( command ls -lh "${PACKAGE}" | awk '{print $5}' )"

  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${PACKAGE}" -C "${HERE}/${VERSION}/" --strip-components=1 || { echo "ERROR: FAILED to extract ${PACKAGE_NAME}" >&2; exit 1; }

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: $(c 0Yi)%s $(c 0Ci)%s$(c) has been setup to $(c 0B)%s → %s$(c)\n" "${BIN_NAME}" "v${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"
  printf "    RUNTIME: $(c 0Bi)%s$(c). To use the latest version, add the following to your shell config:\n" "${HERE}/latest/bin/${BIN_NAME}"
  printf "             $(c 0Gi)\$ export PATH=\"%s:\$PATH$(c)\"\n" "${HERE}/latest/bin"
}

function main() {
  printf "==> %s\n" "${PACKAGE_NAME}"
  clean
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
