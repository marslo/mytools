#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-04-15 15:08:48
#    LastChange : 2026-09-02 21:48:57
#         Usage : to upgrade neovim in Linux/ubuntu
#                 $ mkdir -p /opt/neovim
#                 $ cp update.sh /opt/neovim/ && cd /opt/neovim/
#                 $ bash update.sh
# =============================================================================

set -euo pipefail

declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='neovim/neovim'
declare -r BIN_NAME='nvim'
declare -r VERSION="$( curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name )"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }
declare -r PACKAGE_NAME="nvim-linux-$( uname -m ).tar.gz"
declare -r FOLDER_NAME="${PACKAGE_NAME%.tar.gz}"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE_NAME}" && rm -f "${PACKAGE_NAME}" || :
  test -d "${FOLDER_NAME}"  && rm -rf "${FOLDER_NAME}" || :
}

function setup() {
  curl -fsSL --max-time 240 -o "${HERE}/${PACKAGE_NAME}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}" || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${HERE}/${PACKAGE_NAME}" -C "${HERE}/${VERSION}/" --strip-components=1 || { echo -e "ERROR: Failed to extract ${PACKAGE_NAME}." >&2; exit 1; }

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: %s %s has been installed to %s → %s\n" "${BIN_NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"
  printf "             To use the latest version, add the following to your shell config:\n"
  printf "             \$ export PATH=\"%s:\$PATH\"\n" "${HERE}/latest/bin"
}

function main() {
  printf "==> %s/%s\n" "${VERSION}" "${PACKAGE_NAME}"
  cleanup
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
