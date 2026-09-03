#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-05-14 03:01:06
#    LastChange : 2026-09-03 03:08:14
#         Usage : to install or upgrade eza in Linux/ubuntu
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='eza-community/eza'
declare -r BIN_NAME='eza'
declare -r VERSION="$( curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name )"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }
declare -r PACKAGE_NAME="eza_$(uname -m)-unknown-linux-gnu.tar.gz"
declare -r PACKAGE="${HERE}/${PACKAGE_NAME}"

# shellcheck disable=SC2015
function clean() {
  test -f "${PACKAGE}" && rm -f "${PACKAGE}"  || :
  test -d "${VERSION}" && rm -rf "${VERSION}" || :
}

function setup() {
  curl -fsSL --max-time 240 -o "${PACKAGE}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}" || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${PACKAGE}" -C "${HERE}/${VERSION}/" --strip-components=1 || { echo -e "ERROR: Failed to extract ${PACKAGE_NAME}." >&2; exit 1; }

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: $(c 0Ys)%s $(c 0Ci)%s$(c) has been setup to $(c 0B)%s → %s$(c)\n" "${BIN_NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"
  printf "             You can create a symlink to the binary in $(c 0B)%s$(c) by running:\n" '/usr/local/bin'
  printf "             $(c 0Gi)\$ sudo ln -s %s /usr/local/bin/eza$(c)\n" "${HERE}/${VERSION}/${BIN_NAME}"
}

function theme() {
  local _prefix="${HOME}"/.config/eza
  local _theme_path="${_prefix}"/eza-themes
  test -d "${_prefix}" || mkdir -p "${_prefix}"

  if test -d "${_theme_path}" && git -C "${_theme_path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${_theme_path}" pull --rebase
    printf "$(c Y)%s$(c) themes has been updated to the latest version in $(c B)%s$(c)\n" "${BIN_NAME}" "${_theme_path}"
  else
    git clone https://git::@github.com/eza-community/eza-themes.git "${_theme_path}"
    printf "$(c Y)%s$(c) themes has been cloned to $(c B)%s$(c)\n" "${BIN_NAME}" "${_theme_path}"
  fi
}

function main() {
  printf "==> %s/%s\n" "${VERSION}" "${PACKAGE_NAME}"
  clean
  setup
  theme
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
