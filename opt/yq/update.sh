#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 18:49:32
#    LastChange : 2026-09-03 02:49:53
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

# shellcheck disable=SC2155
declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='mikefarah/yq'
declare -r BIN_NAME="$( basename "${REPO_PATH}" )"
declare -r VERSION="$( curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name )"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }
declare -r PACKAGE_NAME="${BIN_NAME}_$( uname | tr '[:upper:]' '[:lower:]' )_$( uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/' )"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE_NAME:-}" && rm -f "${PACKAGE_NAME:-}" || :
  test -f "${VERSION:-}"      && rm -f "${VERSION:-}"      || :
}

function setup() {
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  curl -fsSL --max-time 240 -o "${HERE}/${VERSION}/${PACKAGE_NAME}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}" || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }
  chmod +x "${HERE}/${VERSION}/${PACKAGE_NAME}"

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: $(c 0Ys)%s $(c 0Ci)%s$(c) has been installed to $(c 0B)%s → %s$(c)\n" "${BIN_NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"

  test -d "${HOME}/.local/bin" || mkdir -p "${HOME}/.local/bin"
  ln -sf "${HERE}/latest/${PACKAGE_NAME}" "${HOME}/.local/bin/${BIN_NAME}"
  printf "==> SUCCESS: $(c 0Ys)%s $(c 0Ci)%s$(c) has been linked to $(c 0Mi)%s$(c). To use the latest version, add the following to your shell config:\n"  "${BIN_NAME}" "${VERSION}" "${HOME}/.local/bin/${BIN_NAME}"
  printf "             $(c 0Gi)\$ export PATH=\"%s:\$PATH$(c)\"\n" "${HOME}/.local/bin"
}

function main() {
  printf "==> %s/%s\n" "${VERSION}" "${PACKAGE_NAME}"
  cleanup
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
