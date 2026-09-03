#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 18:18:01
#    LastChange : 2026-09-03 02:39:17
#         Usage : to install/upgrade btop in Linux/ubuntu
#                 $ mkdir -p /opt/btop
#                 $ cp update.sh /opt/btop/ && cd /opt/btop/
#                 $ bash update.sh
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='aristocratos/btop'
declare -r BIN_NAME='btop'
declare -r VERSION="$(curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name)"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }
declare -r PACKAGE_NAME="${BIN_NAME}-$(uname -m)-unknown-linux-musl.tar.gz"
declare -r PACKAGE="${HERE}/${PACKAGE_NAME}"
declare -r FOLDER_NAME="${PACKAGE_NAME%.tar.gz}"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE}"     && rm -f "${PACKAGE}"      || :
  test -d "${FOLDER_NAME}" && rm -rf "${FOLDER_NAME}" || :
}

function setup() {
  curl -fsSL --max-time 240 -o "${PACKAGE}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}" || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${PACKAGE}" -C "${HERE}/${VERSION}/" --strip-components=2 || { echo -e "ERROR: Failed to extract ${PACKAGE_NAME}." >&2; exit 1; }

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: $(c 0Yi)%s $(c 0Ci)%s$(c) has been setup to $(c 0B)%s → %s$(c)\n" "${BIN_NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"
}

# shellcheck disable=SC2015
function theme() {
  local _dir="${HERE}/btop-themes"
  local _theme_path="${HOME}"/.config/btop/themes

  if test -d "${_dir}" && git -C "${_dir}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${_dir}" fetch --depth 1 origin && git -C "${_dir}" reset --hard '@{u}' || { printf 'ERROR: Failed to clone btop theme repository.\n' >&2; exit 1; }
    printf "$(c Ys)%s$(c) themes has been updated to the latest version in $(c 0Ci)%s$(c)\n" "${BIN_NAME}" "${_dir}"
  else
    git clone --depth 1 --filter=blob:none --sparse "https://git::@github.com/${REPO_PATH}.git" "${_dir}" || { printf 'ERROR: Failed to clone btop theme repository.\n' >&2; exit 1; }
    git -C "${_dir}" sparse-checkout set themes
    printf "$(c Ys)%s$(c) themes has been cloned to $(c B)%s$(c)\n" "${BIN_NAME}" "${_dir}"
  fi

  test -d "${_theme_path}" || mkdir -p "${_theme_path}"
  command cp -f "${_dir}"/themes/*.theme "${_theme_path}" || { echo -e "ERROR: copy btop themes to '${_theme_path}' failed." >&2; exit 1; }
  printf "==> SUCCESS: btop themes have been installed to $(c Bi)%s$(c)\n" "${_theme_path}"
}

function main() {
  printf '==> %s/%s\n' "${VERSION}" "${PACKAGE_NAME}"
  cleanup
  setup
  theme
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
