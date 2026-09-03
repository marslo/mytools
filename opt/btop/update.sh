#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 18:18:01
#    LastChange : 2026-09-02 18:27:09
#         Usage : to install/upgrade btop in Linux/ubuntu
#                 $ mkdir -p /opt/btop
#                 $ cp update.sh /opt/btop/ && cd /opt/btop/
#                 $ bash update.sh
# =============================================================================

set -euo pipefail

declare -r HERE="$( dirname "$( readlink -f "${BASH_SOURCE[0]:-$0}" )" )"
declare -r REPO_PATH='aristocratos/btop'
declare -r VERSION="$(curl -fsSL https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name)"
declare -r PACKAGE_NAME="btop-$(uname -m)-unknown-linux-musl.tar.gz"
declare -r FOLDER_NAME="${PACKAGE_NAME%.tar.gz}"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE_NAME}" && rm -f "${PACKAGE_NAME}" || :
  test -d "${FOLDER_NAME}"  && rm -rf "${FOLDER_NAME}" || :
}

function setup() {
  curl -fsSL -o "${HERE}/${PACKAGE_NAME}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}"
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${HERE}/${PACKAGE_NAME}" -C "${HERE}/${VERSION}/" --strip-components=2

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"

  echo ">> SUCCESS: btop ${VERSION} has been installed to ${HERE}/latest → ${HERE}/${VERSION}"
}

function main() {
  cleanup
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
