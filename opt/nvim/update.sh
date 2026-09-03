#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-04-15 15:08:48
#    LastChange : 2026-05-14 02:51:40
#         Usage : to upgrade neovim in Linux/ubuntu
#                 $ mkdir -p /opt/neovim
#                 $ cp update.sh /opt/neovim/ && cd /opt/neovim/
#                 $ bash update.sh
# =============================================================================

set -euo pipefail

declare -r HERE="$( dirname "$( readlink -f "${BASH_SOURCE[0]:-$0}" )" )"
declare -r REPO_PATH='neovim/neovim'
declare -r VERSION="$(curl -fsSL https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name)"
declare -r PACKAGE_NAME="nvim-linux-$(uname -m).tar.gz"
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
}

function main() {
  cleanup
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
