#!/usr/bin/env bash
# =============================================================================
#      FileName : build.sh
#        Author : marslo
#       Created : 2025-10-27 18:48:29
#    LastChange : 2026-09-02 21:52:40
#   RequiredEnv : - gcc/make : sudo apt install build-essential
#                 - dev packages: sudo apt install libperl-dev ruby-dev python3-dev liblua5.4-dev libncurses-dev libsodium-dev
# =============================================================================

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r LOCAL_REPO="${HERE}/vim.git"
declare -r BIN_NAME='vim'
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

  if test -d "${LOCAL_REPO}" && git -C "${LOCAL_REPO}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${LOCAL_REPO}" clean -dffx
    git -C "${LOCAL_REPO}" fetch --all --progress --prune
    git -C "${LOCAL_REPO}" reset --hard origin/"${BRANCH}"
    printf "==> %s repo has been updated to the latest revision %s in %s\n" ${BIN_NAME} "$(git -C "${LOCAL_REPO}" rev-parse --short=9 HEAD)" "${LOCAL_REPO}"
  else
    git clone https://git::@github.com/vim/vim.git "${LOCAL_REPO}"
    printf "==> %s repo has been cloned to %s\n" "${BIN_NAME}" "${LOCAL_REPO}"
  fi
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
  pushd . >/dev/null || exit 1

  if ! "${CLEAN}" && ! "${INSTALL}" ; then
    CLEAN=true; INSTALL=true
  fi

  "${CLEAN}" && { clean "${BRANCH}" || exit $?; }
  cd "${LOCAL_REPO}" || exit 1

  if "${INSTALL}" ; then
    config || { local _ce=$?; echo -e "ERROR: configure failed, please check the output above for details." >&2; exit "${_ce}"; }
    build  || { local _be=$?; echo -e "ERROR: build failed, please check the output above for details." >&2; exit "${_be}"; }
    printf "==> SUCCEED: Vim has been installed to %s. setup your PATH via:\n" "${PREFIX}/vim/bin/${BIN_NAME}"
    printf "            \`export PATH=%s:\$PATH\`" "${PREFIX}/vim/bin"
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
