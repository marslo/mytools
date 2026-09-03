#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 22:21:09
#    LastChange : 2026-09-02 22:33:49
#   Description : standalone install of the latest tree-sitter CLI (prebuilt binary), also can be installed by :
#                 - cargo: cargo install tree-sitter-cli
#                 - npm: npm install -g tree-sitter-cli
# =============================================================================

set -euo pipefail

declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r REPO_PATH='tree-sitter/tree-sitter'
declare -r BIN_NAME='tree-sitter'
declare -r LOCAL_BIN_DIR="${HOME}/.local/bin"
declare -r VERSION="$( curl -fsSL --max-time 20 https://api.github.com/repos/${REPO_PATH}/releases/latest | jq -r .tag_name )"
test -n "${VERSION}" || { echo "ERROR: FAILED to resolve ${BIN_NAME} version in ${REPO_PATH}" >&2; exit 1; }

# detect os/arch -> release asset name
case "$( uname -s )" in
  Linux  ) OS='linux'  ;;
  Darwin ) OS='macos'  ;;
  *      ) echo "ERROR: unsupported OS: $( uname -s )" >&2; exit 1 ;;
esac

case "$( uname -m )" in
  x86_64  | amd64 ) ARCH='x64'   ;;
  aarch64 | arm64 ) ARCH='arm64' ;;
  *               ) echo "ERROR: unsupported arch: $( uname -m )" >&2; exit 1 ;;
esac
declare -r PACKAGE_NAME="${BIN_NAME}-${OS}-${ARCH}.gz"

# shellcheck disable=SC2015
function cleanup() {
  test -f "${PACKAGE_NAME}" && rm -f "${PACKAGE_NAME}" || :
  test -d "${VERSION}"      && rm -rf "${VERSION}"     || :
}

function setup() {
  curl -fsSL --max-time 240 -o "${HERE}/${PACKAGE_NAME}" "https://github.com/${REPO_PATH}/releases/download/${VERSION}/${PACKAGE_NAME}" || { echo -e "ERROR: Failed to download ${PACKAGE_NAME} from GitHub releases." >&2; exit 1; }

  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  gunzip -c "${HERE}/${PACKAGE_NAME}" > "${HERE}/${VERSION}/${BIN_NAME}" || { echo -e "ERROR: Failed to extract ${PACKAGE_NAME}." >&2; exit 1; }
  chmod +x "${HERE}/${VERSION}/${BIN_NAME}" || { echo -e "ERROR: Failed to make ${BIN_NAME} executable." >&2; exit 1; }
  printf '==> installed: %s\n' "${HERE}/${VERSION}/${BIN_NAME}"

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: %s %s has been download and extract to %s → %s\n" "${BIN_NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"

  install -m 0755 "${HERE}/latest/${BIN_NAME}" "${LOCAL_BIN_DIR}/${BIN_NAME}"
  printf "==> installed: %s\n" "${LOCAL_BIN_DIR}/${BIN_NAME}"
}

function verify() {
  "${LOCAL_BIN_DIR}/${BIN_NAME}" --version || { echo -e "ERROR: Failed to verify ${BIN_NAME} installation." >&2; exit 1; }
}

function main() {
  printf "==> %s/%s\n" "${VERSION}" "${PACKAGE_NAME}"
  cleanup
  setup
  verify
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
