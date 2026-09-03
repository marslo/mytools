#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-03 01:02:11
#    LastChange : 2026-09-03 02:33:54
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
declare -r REPO_PATH='sharkdp/bat'
declare -r BIN_NAME='bat'
declare -r IS_SUDO=$( [[ $EUID -eq 0 ]] && echo true || echo false )
declare VERSION="$( curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name )"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }
VERSION="${VERSION#v}"
# declare -r ARCH="$( dpkg --print-architecture )"

declare DEB_ARCH ARCH TARGET PACKAGE_NAME
case "$( uname -m )" in
  x86_64  | amd64 ) DEB_ARCH='amd64' ; ARCH='x86_64'  ;;
  aarch64 | arm64 ) DEB_ARCH='arm64' ; ARCH='aarch64' ;;
  armv7l  | armhf ) DEB_ARCH='armhf' ; ARCH='arm'     ;;
  i686    | i386  ) DEB_ARCH='i686'  ; ARCH='i686'    ;;
  *               ) echo "ERROR: unsupported arch: $( uname -m )" >&2; exit 1 ;;
esac
case "$( uname -s )" in
  Darwin ) PACKAGE_NAME="${BIN_NAME}-v${VERSION}-${ARCH}-apple-darwin.tar.gz" ;;
  Linux  ) if "${IS_SUDO}" && command -v dpkg >/dev/null 2>&1; then
             PACKAGE_NAME="${BIN_NAME}_${VERSION}_${DEB_ARCH}.deb"         # Debian / Ubuntu → deb ── need sudo
           else
             if [ "${ARCH}" = arm ]; then
               TARGET="${ARCH}-unknown-linux-musleabihf"                   # RHEL / Fedora / Alpine (musl)
             else
               TARGET="${ARCH}-unknown-linux-musl"
             fi
             PACKAGE_NAME="${BIN_NAME}-v${VERSION}-${TARGET}.tar.gz"
           fi ;;
  *      ) echo "ERROR: unsupported OS: $( uname -s )" >&2; exit 1 ;;
esac
declare -r PACKAGE="${HERE}/${PACKAGE_NAME}"
declare -r USAGE="NAME
  ${ME} - install or update ${BIN_NAME} from GitHub releases

SYNOPSIS
  \$ ${ME} [options]

OPTIONS
  -h, --help      Show this help message and exit

EXAMPLES
  \$ ${ME}        $(c 0Wdi)# install tar.gz package to $(c 0Gi)\$HOME/.local/bin/${BIN_NAME}$(c)
  \$ sudo ${ME}   $(c 0Wdi)# install deb package to $(c 0Gi)/usr/bin/${BIN_NAME} $(c 0Wdi)── for $(c 0Mi)Debian / Ubuntu$(c 0Wdi) only $(c)
"

# shellcheck disable=SC2015
function clean() {
  test -f "${PACKAGE}" && rm -f "${PACKAGE}"  || :
  test -d "${VERSION}" && rm -rf "${VERSION}" || :
}

function download() {
  curl -fsSL --max-time 240 -o "${PACKAGE}" "https://github.com/${REPO_PATH}/releases/download/v${VERSION}/${PACKAGE_NAME}" || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }
}

function setup() {
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${PACKAGE}" -C "${HERE}/${VERSION}/" --strip-components=1 || { echo -e "ERROR: Failed to extract ${PACKAGE_NAME}." >&2; exit 1; }
  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: $(c 0Yi)%s $(c 0Ci)%s$(c) has been installed to $(c 0B)%s → %s$(c)\n" "${BIN_NAME}" "v${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"

  test -d "${HOME}/.local/bin" || mkdir -p "${HOME}/.local/bin"
  ln -sf "${HERE}/latest/${BIN_NAME}" "${HOME}/.local/bin/${BIN_NAME}"
  printf "==> SUCCESS: $(c 0Yi)%s $(c 0Ci)%s$(c) has been linked to $(c 0Mi)%s$(c). To use the latest version, add the following to your shell config:\n"  "${BIN_NAME}" "v${VERSION}" "${HOME}/.local/bin/${BIN_NAME}"
  printf "             $(c 0Gi)\$ export PATH=\"%s:\$PATH$(c)\"\n" "${HOME}/.local/bin"
  printf "==> CACHE:   To rebuild bat cache via $(c 0Gi)%s$(c)\n" "\$ bat cache --build"
}

function install() {
  case "${PACKAGE_NAME}" in
    *.deb    ) { sudo dpkg -i "${PACKAGE}" || sudo apt-get install -f -y; } || { echo -e "ERROR: Failed to install ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; } ;;
    *.tar.gz ) setup || { echo -e "ERROR: Failed to setup ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; } ;;
    *        ) echo "ERROR: unsupported package type: ${PACKAGE_NAME}" >&2; exit 1 ;;
  esac
}

function main() {
  printf "==> %s/%s\n" "${VERSION}" "${PACKAGE_NAME}"
  clean
  download || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }
  install  || { echo -e "ERROR: Failed to install ${PACKAGE_NAME} from GitHub releases." >&2;  exit 1; }
}

while test $# -gt 0; do
  case "$1" in
    -h | --help ) echo -e "${USAGE}" >&2; exit 0;;
    *           ) echo "ERROR: unknown option '$1'"; exit 1;;
  esac
done

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
