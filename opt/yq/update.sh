#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 18:49:32
#    LastChange : 2026-09-02 18:55:59
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='mikefarah/yq'
declare -r VERSION="$(curl -fsSL https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name)"
declare -r PACKAGE_NAME="yq_$(uname | tr '[:upper:]' '[:lower:]')_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/')"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE_NAME:-}" && rm -f "${PACKAGE_NAME:-}" || :
  test -f "${VERSION:-}"      && rm -f "${VERSION:-}"      || :
}

function setup() {
  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  curl -fsSL -o "${HERE}/${VERSION}/${PACKAGE_NAME}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}"
  chmod +x "${HERE}/${VERSION}/${PACKAGE_NAME}"

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  echo ">> SUCCESS: yq ${VERSION} has been installed to ${HERE}/latest → ${HERE}/${VERSION}"

  test -d "${HOME}/.local/bin" || mkdir -p "${HOME}/.local/bin"
  ln -sf "${HERE}/latest/${PACKAGE_NAME}" "${HOME}/.local/bin/yq"
  echo ">> SUCCESS: yq ${VERSION} has been linked to ${HOME}/.local/bin/yq"
}

function main() {
  cleanup
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
