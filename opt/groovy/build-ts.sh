#!/usr/bin/env bash
# =============================================================================
#      FileName : build-ts.sh
#        Author : marslo
#       Created : 2026-06-09 16:05:37
#    LastChange : 2026-09-02 23:25:09
#    Description : build tree-sitter groovy parser - vim/nvim
# =============================================================================
# codesign --remove-signature ~/.local/share/nvim/site/parser/groovy.so
# codesign --force --sign -   ~/.local/share/nvim/site/parser/groovy.so

set -euo pipefail

# shellcheck disable=SC2155
declare -r HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"
declare -r LOCAL_REPO="${HERE}/tree-sitter-groovy.git"
declare -r BIN_NAME='tree-sitter-groovy'
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
declare -r BRANCH='main'
declare CLEAN=false
declare USAGE="NAME
  ${ME} - build customized tree-sitter groovy parser for vim/nvim

SYNOPSIS
  \$ ${ME} [options]

OPTIONS
  -c, --clean      clean the local repo and update to the latest revision
  -h, --help       show this help message
"

function clean() {
  local _branch="${1:-${BRANCH}}"

  if test -d "${LOCAL_REPO:-}" && git -C "${LOCAL_REPO:-}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${LOCAL_REPO}" clean -dffx
    git -C "${LOCAL_REPO}" fetch --all --progress --prune
    git -C "${LOCAL_REPO}" reset --hard origin/"${BRANCH}"
    printf '==> %s repo has been updated to the latest revision %s in %s\n' "${BIN_NAME}" "$( git -C "${LOCAL_REPO}" rev-parse --short=9 HEAD )" "${LOCAL_REPO}"
  else
    git clone https://git::@github.com/marslo/tree-sitter-groovy.git "${LOCAL_REPO}"
    printf '==> %s repo has been cloned to %s\n' "${BIN_NAME}" "${LOCAL_REPO}"
  fi
}

# call make nvim-install for both nvim/cli build and install
function installts() {
  local _url; _url="$( git -C "${LOCAL_REPO}" remote get-url origin 2>/dev/null )"
  case "${_url}" in
    *marslo/tree-sitter-groovy* ) command make -C "${LOCAL_REPO}" nvim-install ;;
    *                           ) build ;;
  esac
}

# shellcheck disable=SC2015
function build() {
  local _nvimso="${HOME}/.local/share/nvim/site/parser/groovy.so"
  local _os; _os="$( uname )"
  local _cliso
  test 'Darwin' = "${_os}" && _cliso="${HOME}/.cache/tree-sitter/lib/groovy.dylib" || _cliso="${HOME}/.cache/tree-sitter/lib/groovy.so"

  tree-sitter generate
  tree-sitter build -o groovy.so
  printf '==> groovy parser has been built successfully in %s\n' "${LOCAL_REPO}/groovy.so"
  test 'Darwin' = "${_os}" && { codesign --force --sign - groovy.so; printf '==> groovy parser codesigned successfully (groovy.so)\n'; } || :

  mkdir -p "${_nvimso%/*}" "${_cliso%/*}"
  command cp -f groovy.so "${_nvimso}"
  printf '==> groovy parser for vim/nvim installed in %s\n' "${_nvimso}"

  tree-sitter build -o "${_cliso}"
  printf '==> groovy parser for CLI installed in %s\n' "${_cliso}"
  test 'Darwin' = "${_os}" && { codesign --force --sign - "${_cliso}"; printf '==> groovy parser for CLI codesigned successfully (%s)\n' "${_cliso}"; } || :
}

# verify
function verify() {
  command nvim --headless -u NONE -c "set rtp+=~/.local/share/nvim/site" -c "lua vim.treesitter.language.add('groovy'); print('==> nvim OK')" -c "qa!"
}

function main() {
  pushd . >/dev/null || exit 1

  { "${CLEAN}" || ! test -d "${LOCAL_REPO}"; } && { clean "${BRANCH}" || exit $?; }

  cd "${LOCAL_REPO}" || exit 1
  build || { echo "ERROR: Failed to build ${BIN_NAME} parser" >&2; exit 1; }
  printf '==> %s parser has been built successfully in %s\n' "${BIN_NAME}" "${LOCAL_REPO}"

  verify || { echo "ERROR: Failed to verify ${BIN_NAME} parser" >&2; exit 1; }
}

while test $# -gt 0; do
  case "$1" in
    -c | --clean ) CLEAN=true; shift ;;
    -h | --help  ) echo -e "${USAGE}" >&2; exit 0 ;;
    *            ) echo "ERROR: unknown option '$1'" >&2; exit 1 ;;
  esac
done

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
