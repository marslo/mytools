#!/usr/bin/env bash
# shellcheck disable=SC2155
# =============================================================================
#      FileName : build.sh
#        Author : marslo
#       Created : 2025-10-27 18:48:29
#    LastChange : 2026-09-03 02:31:47
#   RequiredEnv : - gcc/make : sudo apt install build-essential
#                 - dev packages: sudo apt install libperl-dev ruby-dev python3-dev liblua5.4-dev libncurses-dev libsodium-dev
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

declare -r HERE="$( cd "$(dirname "${BASH_SOURCE[0]:-$0}")" >/dev/null 2>&1 && pwd -P )"
declare -r LOCAL_REPO="${HERE}/vim.git"
declare -r BIN_NAME='vim'
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
declare -r BRANCH='master'
declare -r LOG_PATH="${HERE}/logs/$(date +%y%m%d%H%M)"

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
  -v              verbose output, can be repeated for more verbosity. $(c 0i)(max: $(c 0Yi)1$(c))$(c)
  -h, --help      show this help message and exit

TIP
  • \`\$ sudo bash ${ME}\` #(c 0Wdi)# build and install vim to /usr/local/vim$(c)
  • \`\$ bash ${ME}\`      $(c 0Wdi)#  build and install vim to ~/.local/vim$(c)
  • dependencies
    $(c 0Gi)\`\`\`
    sudo apt install build-essential libperl-dev ruby-dev python3-dev liblua5.4-dev libncurses-dev libsodium-dev
    \`\`\`$(c)
"

function clean() {
  local _branch="${1:-${BRANCH}}"

  if test -d "${LOCAL_REPO}" && git -C "${LOCAL_REPO}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local _cmd=( git -C "${LOCAL_REPO}" clean -dffx )
    # shellcheck disable=SC2015
    test "${VERBOSE}" -ge 1 && "${_cmd[@]}" || { "${_cmd[@]}" > "${LOG_PATH}/git-clean.log" 2>&1; }
    git -C "${LOCAL_REPO}" fetch --all --progress --prune
    git -C "${LOCAL_REPO}" reset --hard origin/"${BRANCH}"
    printf "==> %s repo has been updated to the latest revision $(c Ci)%s$(c) in $(c B)%s$(c)\n" ${BIN_NAME} "$(git -C "${LOCAL_REPO}" rev-parse --short=9 HEAD)" "${LOCAL_REPO}"
  else
    git clone https://git::@github.com/vim/vim.git "${LOCAL_REPO}"
    printf "==> %s repo has been cloned to $(c 0B)%s$(c)\n" "${BIN_NAME}" "${LOCAL_REPO}"
  fi
}

function config() {
  local _lua_bin; _lua_bin="$(command -v lua)" || { echo "ERROR: lua not found, please install it first." >&2; exit 1; }
  local -r _lua_prefix=${_lua_bin%/bin/lua}
  local -r _cmd=( ./configure --with-features=huge
                  --enable-cscope
                  --enable-terminal
                  --enable-autoservername
                  --enable-multibyte
                  --enable-nls
                  --enable-libsodium
                  --with-tlib=ncursesw
                  --enable-gui=no
                  --without-x
                  --enable-rubyinterp=dynamic
                  --enable-perlinterp=dynamic
                  --enable-python3interp=dynamic
                  --with-python3-config-dir="$(python"${PYTHON_VERSION}"-config --configdir)"
                  --enable-luainterp=dynamic
                  --with-lua-prefix="${_lua_prefix}"
                  --with-compiledby="marslo <marslo.jiao@gmail.com>"
                  --prefix="${PREFIX}"/vim
                  --exec-prefix="${PREFIX}"/vim
                  --enable-fail-if-missing
              )
  # shellcheck disable=SC2015
  test "${VERBOSE}" -ge 1 && "${_cmd[@]}" || { "${_cmd[@]}" > "${LOG_PATH}/vim-config.log" 2>&1; }
}

function build() {
  local -a _cmd=()
  # shellcheck disable=SC2015
  test "${VERBOSE}" -ge 1 && make -j"$(nproc)" || { make -j"$(nproc)" >"${LOG_PATH}/vim-build.log" 2>&1; }
  # shellcheck disable=SC2015
  "${IS_SUDO}" && _cmd=( sudo make install ) || _cmd=( make install )
  # shellcheck disable=SC2015
  test "${VERBOSE}" -ge 1 && "${_cmd[@]}" || { "${_cmd[@]}" >"${LOG_PATH}/vim-install.log" 2>&1; }
  printf "==> SUCCEED: Vim has been installed to $(c 0Bi)%s$(c). setup your PATH via:\n" "${PREFIX}/vim/bin/${BIN_NAME}"
  printf "            $(c 0Gi)\`export PATH=%s:\$PATH\`$(c)" "${PREFIX}/vim/bin"
}

declare CLEAN=false
declare INSTALL=false
declare VERBOSE=0

function main() {
  pushd . >/dev/null || exit 1
  test -d "${LOG_PATH}" || mkdir -p "${LOG_PATH}"

  if ! "${CLEAN}" && ! "${INSTALL}" ; then
    CLEAN=true; INSTALL=true
  fi

  "${CLEAN}" && { clean "${BRANCH}" || exit $?; }
  cd "${LOCAL_REPO}" || exit 1

  if "${INSTALL}" ; then
    config || { local _ce=$?; echo -e "ERROR: configure failed, please check the output above for details." >&2; exit "${_ce}"; }
    build  || { local _be=$?; echo -e "ERROR: build failed, please check the output above for details." >&2;     exit "${_be}"; }
  fi

  popd >/dev/null || exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i | --install ) INSTALL=true; shift;;
    -c | --clean   ) CLEAN=true; shift;;
    -v             ) VERBOSE=$(( ${#1} - 1 ))  ; shift    ;;
    -h | --help    ) echo -e "${USAGE}" >&2; exit 0;;
    -*             ) echo "ERROR: unknown option '$1'"; exit 1;;
  esac
done

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
