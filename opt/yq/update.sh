#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 18:49:32
#    LastChange : 2026-09-02 21:50:07
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='mikefarah/yq'
declare -r NAME="$( basename "${REPO_PATH}" )"
declare -r VERSION="$( curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name )"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }
declare -r PACKAGE_NAME="${NAME}_$( uname | tr '[:upper:]' '[:lower:]' )_$( uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/' )"

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
  printf "==> SUCCESS: %s %s has been installed to %s → %s\n" "${NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"

  test -d "${HOME}/.local/bin" || mkdir -p "${HOME}/.local/bin"
  ln -sf "${HERE}/latest/${PACKAGE_NAME}" "${HOME}/.local/bin/${NAME}"
  printf "==> SUCCESS: %s %s has been linked to %s. To use the latest version, add the following to your shell config:\n"  "${NAME}" "${VERSION}" "${HOME}/.local/bin/${NAME}"
  printf "             \$ export PATH=\"%s:\$PATH\"\n" "${HOME}/.local/bin"
}

function main() {
  printf "==> %s/%s\n" "${VERSION}" "${PACKAGE_NAME}"
  cleanup
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
