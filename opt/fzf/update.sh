#!/usr/bin/env bash
# =============================================================================
#      FileName : update.sh
#        Author : marslo
#       Created : 2026-05-19 23:01:10
#    LastChange : 2026-05-20 19:26:12
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
# shellcheck disable=SC2155
declare arch=$(uname -m)

case "${arch}" in
    arm64 | aarch64        ) name='arm8'  ;;
    amd64 | x86_64 | i86pc ) name='amd64' ;;
    *                      ) echo "ERROR: '${arch}' is not supported." >&2; exit 1 ;;
esac

# shellcheck disable=SC2155
declare -r BIN="${HERE}"/fzf.git/target/fzf-"$(go env GOOS)"_"${name}"

test -d "${HERE}"/fzf.git || git clone https://github.com/junegunn/fzf.git "${HERE}"/fzf.git
cd "${HERE}"/fzf.git || exit 1

git reset --hard origin/master
git pull --rebase
make clean
make

test -f "${BIN}" && "${BIN}" --version && ln -sf "${BIN}" ~/.local/bin/fzf
~/.local/bin/fzf --version

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
