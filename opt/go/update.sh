#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-09-02 21:25:19
#    LastChange : 2026-09-02 21:49:48
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r BIN_NAME='go'
declare VERSION="$( curl -fsSL --max-time 20 'https://go.dev/VERSION?m=text' | head -1 )"
test -n "${VERSION}" || { echo 'ERROR: FAILED to resolve version' >&2; exit 1; }
declare VERSION="${VERSION#"${BIN_NAME}"}"
declare -r PACKAGE_NAME="${BIN_NAME}${VERSION}.$( uname | tr '[:upper:]' '[:lower:]' )-$( uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/' ).tar.gz"
declare -r FOLDER_NAME="${PACKAGE_NAME%.tar.gz}"

# shellcheck disable=SC2015
function clean() {
  test -f "${PACKAGE_NAME}" && rm -f "${PACKAGE_NAME}" || :
  test -d "${FOLDER_NAME}"  && rm -rf "${FOLDER_NAME}" || :
}

function setup() {
  curl -fsSL --max-time 240 -o "${HERE}/${PACKAGE_NAME}" "https://go.dev/dl/${PACKAGE_NAME}" || { echo "ERROR: FAILED to download ${PACKAGE_NAME}" >&2; exit 1; }
  printf "==> size: %s\n" "$( command ls -lh "${HERE}/${PACKAGE_NAME}" | awk '{print $5}' )"

  test -d "${HERE}/${VERSION}" || mkdir -p "${HERE}/${VERSION}"
  tar xf "${HERE}/${PACKAGE_NAME}" -C "${HERE}/${VERSION}/" --strip-components=1 || { echo "ERROR: FAILED to extract ${PACKAGE_NAME}" >&2; exit 1; }

  test -L "${HERE}/latest" && unlink "${HERE}/latest"
  ln -sf "${HERE}/${VERSION}" "${HERE}/latest"
  printf "==> SUCCESS: %s v%s has been setup to %s → %s\n" "${BIN_NAME}" "${VERSION}" "${HERE}/latest" "${HERE}/${VERSION}"
  printf "    RUNTIME: %s.To use the latest version, add the following to your shell config:\n" "${HERE}/latest/bin/${BIN_NAME}"
  printf "             \$ export PATH=\"%s:\$PATH\"\n" "${HERE}/latest/bin"
}

function main() {
  printf "==> %s\n" "${PACKAGE_NAME}"
  clean
  setup
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
