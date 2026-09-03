#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-05-14 03:01:06
#    LastChange : 2026-09-02 19:20:33
#         Usage : to install or upgrade eza in Linux/ubuntu
# =============================================================================

set -euo pipefail

declare -r HERE="$( dirname "$( readlink -f "${BASH_SOURCE[0]:-$0}" )" )"
declare -r REPO_PATH='eza-community/eza'
declare -r VERSION="$(curl -fsSL https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name)"
declare -r PACKAGE_NAME="eza_$(uname -m)-unknown-linux-gnu.tar.gz"
declare -r FOLDER_NAME="${PACKAGE_NAME%.tar.gz}"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE_NAME}" && rm -f "${PACKAGE_NAME}" || :
  test -d "${FOLDER_NAME}"  && rm -rf "${FOLDER_NAME}" || :
}

function setup() {
  curl -fsSL -o "${HERE}/${PACKAGE_NAME}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}"
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${HERE}/${PACKAGE_NAME}" -C "${HERE}/${VERSION}/" --strip-components=1

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"

  printf "eza %s has been setup to %s/%s\n" "${VERSION}" "${HERE}" "${VERSION}"
  printf 'You can create a symlink to the binary in /usr/local/bin by running:\n'
  printf "  \$ sudo ln -s %s/%s/eza /usr/local/bin/eza\n" "${HERE}" "${VERSION}"
}

function theme() {
  local _prefix="${HOME}"/.config/eza
  local _theme_path="${_prefix}"/eza-themes
  test -d "${_prefix}" || mkdir -p "${_prefix}"

  if test -d "${_theme_path}" && git -C "${_theme_path}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${_theme_path}" pull --rebase
    printf "eza-themes has been updated to the latest version in %s\n" "${_theme_path}"
  else
    git clone https://git::@github.com/eza-community/eza-themes.git "${_theme_path}"
    printf "eza-themes has been cloned to %s\n" "${_theme_path}"
  fi
}

function main() {
  cleanup
  setup
  theme
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
