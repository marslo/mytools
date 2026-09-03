#!/usr/bin/env bash
# =============================================================================
#      FileName : build.sh
#        Author : marslo
#       Created : 2025-10-27 18:48:29
#    LastChange : 2026-09-02 17:45:17
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
declare -r BRANCH='master'
test -d "${HERE}"/vim.git || https://git::@github.com/vim/vim.git "${HERE}"/vim.git
# shellcheck disable=SC2155
declare -r IS_SUDO=$( [[ $EUID -eq 0 ]] && echo true || echo false )
declare PREFIX; "${IS_SUDO}" && PREFIX=/usr/local || PREFIX="${HOME}"/.local
LUA_BIN="$(command -v lua)" || { echo "ERROR: lua not found, please install it first." >&2; exit 1; }
declare -r LUA_PREFIX=${LUA_BIN%/bin/lua}

pushd .
cd "${HERE}"/vim.git || exit 1

git clean -dffx
git fetch --all --progress --prune
git reset --hard origin/"${BRANCH}"

declare PYTHON_VERSION
PYTHON_VERSION="$( /usr/bin/sed -rn 's/^([^[0-9]+)([0-9]+\.[0-9]+).*$/\2/p' < <(command python3 --version) )"
type -P python"${PYTHON_VERSION}"-config >/dev/null || { echo "ERROR: python${PYTHON_VERSION}-config not found, please install it first." >&2; exit 1; }

./configure --with-features=huge \
            --enable-cscope \
            --enable-rubyinterp=dynamic \
            --enable-python3interp=dynamic \
            --with-python3-config-dir="$(python"${PYTHON_VERSION}"-config --configdir)" \
            --enable-luainterp=dynamic \
            --with-lua-prefix="${LUA_PREFIX}" \
            --enable-libsodium \
            --enable-multibyte \
            --with-tlib=ncursesw \
            --enable-terminal \
            --enable-autoservername \
            --enable-nls \
            --with-compiledby="marslo <marslo.jiao@gmail.com>" \
            --prefix="${PREFIX}"/vim \
            --exec-prefix="${PREFIX}"/vim \
            --enable-fail-if-missing

make -j"$(nproc)"

if "${IS_SUDO}"; then
  sudo make install
else
  make install
fi

echo ">> Vim has been installed to ${PREFIX}/vim/bin/vim"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
