#!/usr/bin/env bash
# =============================================================================
#      FileName : build.sh
#        Author : marslo
#       Created : 2025-10-27 18:48:29
#    LastChange : 2026-09-02 18:15:26
#   RequiredEnv : - gcc/make : sudo apt install build-essential
#                 - dev packages: sudo apt install libperl-dev ruby-dev python3-dev liblua5.4-dev libncurses-dev libsodium-dev
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
declare -r BRANCH='master'

declare PYTHON_VERSION; PYTHON_VERSION="$( /usr/bin/sed -rn 's/^([^[0-9]+)([0-9]+\.[0-9]+).*$/\2/p' < <(command python3 --version) )"
type -P python"${PYTHON_VERSION}"-config >/dev/null || { echo "ERROR: python${PYTHON_VERSION}-config not found, please install it first." >&2; exit 1; }

if ! ls /usr/lib/*/libperl.so >/dev/null 2>&1; then
  echo "ERROR: libperl-dev not found, please install via \`sudo apt install libperl-dev\` first." >&2; exit 1;
fi

# shellcheck disable=SC2155
declare -r IS_SUDO=$( [[ $EUID -eq 0 ]] && echo true || echo false )
declare PREFIX; "${IS_SUDO}" && PREFIX=/usr/local || PREFIX="${HOME}"/.local

declare -r USAGE="NAME
  ${ME} - build vim from source

USAGE
  \$ ${ME} [OPTIONS]

OPTIONS
  -c, --clean     clean vim.git and reset to origin/${BRANCH}
  -i, --install   install vim to ${PREFIX}/vim
  -h, --help      show this help message and exit

TIP
  • \`\$ sudo bash ${ME}\` ─ build and install vim to /usr/local/vim
  • \`\$ bash ${ME}\` ─ build and install vim to ~/.local/vim
  • dependencies
    \`\`\`
    sudo apt install build-essential libperl-dev ruby-dev python3-dev liblua5.4-dev libncurses-dev libsodium-dev
    \`\`\`
"

function clean() {
  local _branch="${1:-${BRANCH}}"
  git clean -dffx
  git fetch --all --progress --prune
  git reset --hard origin/"${BRANCH}"
}

function config() {
  local _lua_bin; _lua_bin="$(command -v lua)" || { echo "ERROR: lua not found, please install it first." >&2; exit 1; }
  local -r _lua_prefix=${_lua_bin%/bin/lua}

  ./configure --with-features=huge \
              --enable-cscope \
              --enable-terminal \
              --enable-autoservername \
              --enable-multibyte \
              --enable-nls \
              --enable-libsodium \
              --with-tlib=ncursesw \
              --enable-gui=no \
              --without-x \
              --enable-rubyinterp=dynamic \
              --enable-perlinterp=dynamic \
              --enable-python3interp=dynamic \
              --with-python3-config-dir="$(python"${PYTHON_VERSION}"-config --configdir)" \
              --enable-luainterp=dynamic \
              --with-lua-prefix="${_lua_prefix}" \
              --with-compiledby="marslo <marslo.jiao@gmail.com>" \
              --prefix="${PREFIX}"/vim \
              --exec-prefix="${PREFIX}"/vim \
              --enable-fail-if-missing
}

function build() {
  make -j"$(nproc)"
  # shellcheck disable=SC2015
  "${IS_SUDO}" && sudo make install || make install
}

declare CLEAN=false
declare INSTALL=false

function main() {
  test -d "${HERE}"/vim.git || https://git::@github.com/vim/vim.git "${HERE}"/vim.git
  pushd . >/dev/null   || exit 1
  cd "${HERE}"/vim.git || exit 1

  if ! "${CLEAN}" && ! "${INSTALL}" ; then
    CLEAN=true; INSTALL=true
  fi

  "${CLEAN}" && { clean "${BRANCH}" || exit $?; }
  if "${INSTALL}" ; then
    config || { local _ce=$?; echo -e "ERROR: configure failed, please check the output above for details." >&2; exit "${_ce}"; }
    build  || { local _be=$?; echo -e "ERROR: build failed, please check the output above for details." >&2; exit "${_be}"; }
    echo -e ">> SUCCEED: Vim has been installed to ${PREFIX}/vim/bin/vim"
    echo -e "            setup your PATH via \`export PATH=${PREFIX}/vim/bin:\$PATH\`"
  fi

  popd >/dev/null || exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i | --install ) INSTALL=true; shift;;
    -c | --clean   ) CLEAN=true; shift;;
    -h | --help    ) echo -e "${USAGE}" >&2; exit 0;;
    -*             ) echo "ERROR: unknown option '$1'"; exit 1;;
  esac
done

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
