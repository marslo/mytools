#!/usr/bin/env bash
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-05-19 23:01:10
#    LastChange : 2026-09-02 20:54:06
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
# shellcheck disable=SC2155
declare -r ARCH=$(uname -m)
declare -r LOCAL_REPO="${HERE}/fzf.git"
declare -r BIN_NAME='fzf'
declare -r BRANCH='master'

case "${ARCH}" in
  arm64 | aarch64        ) name='arm8'  ;;
  amd64 | x86_64 | i86pc ) name='amd64' ;;
  *                      ) echo "ERROR: '${ARCH}' is not supported." >&2; exit 1 ;;
esac
# shellcheck disable=SC2155
declare -r BIN="${LOCAL_REPO}/target/${BIN_NAME}-$(go env GOOS)_${name}"

function clean() {
  local _branch="${1:-${BRANCH}}"

  if test -d "${LOCAL_REPO}" && git -C "${LOCAL_REPO}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${LOCAL_REPO}" clean -dffx
    git -C "${LOCAL_REPO}" fetch --all --progress --prune
    git -C "${LOCAL_REPO}" reset --hard origin/"${BRANCH}"
    printf "==> %s repo has been updated to the latest revision %s in %s\n" ${BIN_NAME} "$(git -C "${LOCAL_REPO}" rev-parse --short=9 HEAD)" "${LOCAL_REPO}"
  else
    git clone https://git::@github.com/junegunn/fzf.git "${LOCAL_REPO}"
    printf "==> %s repo has been cloned to %s\n" "${BIN_NAME}" "${LOCAL_REPO}"
  fi
}

function build() {
  make clean
  make -j "$(nproc)"

  test -f "${BIN}" && "${BIN}" --version && ln -sf "${BIN}" ~/.local/bin/fzf
  printf "==> %s has been built successfully in %s\n" "${BIN_NAME}" "${BIN}"
  ~/.local/bin/fzf --version
}

function main() {
  pushd . >/dev/null || exit 1

  clean "${BRANCH}"  || { echo -e "ERROR: Failed to clone/clean ${BIN_NAME} repo." >&2; exit 1; }
  cd "${LOCAL_REPO}" || exit 1
  build || { echo -e "ERROR: Failed to build ${BIN_NAME}." >&2; exit 1; }

  popd >/dev/null || exit 1
}

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
