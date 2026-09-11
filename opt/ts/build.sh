#!/usr/bin/env bash
# =============================================================================
#      FileName : build.sh
#        Author : marslo
#       Created : 2026-06-09 16:05:37
#    LastChange : 2026-09-10 21:05:59
#    Description : build a customized tree-sitter parser (vim/nvim + CLI) by filetype: `--ft <filetype>` -> `tree-sitter-<filetype>.git`
# =============================================================================
# codesign --remove-signature ~/.local/share/nvim/site/parser/<parser>.so
# codesign --force --sign -   ~/.local/share/nvim/site/parser/<parser>.so

set -euo pipefail

HERE="$( cd "$( dirname "${BASH_SOURCE[0]:-$0}" )" && pwd )"; declare -r HERE
ME="$( basename "${BASH_SOURCE[0]:-$0}" )"; declare -r ME
declare -r BRANCH='main'
declare CLEAN=false
declare FT=''

# filetype -> tree-sitter parser / nvim language name (== the `.so` basename). defaults to the filetype itself; only list the ones that differ.
# by default, the parser name is the same as the filetype
declare -rA SO_NAME=(
  [git-config]='git_config'
)

declare USAGE="NAME
  ${ME} - build a customized tree-sitter parser for vim/nvim by filetype

SYNOPSIS
  \$ ${ME} [options]

OPTIONS
  -f, --ft <filetype>  filetype to build; local repo is tree-sitter-<filetype>.git
                       e.g.: --ft groovy     -> tree-sitter-groovy.git
                             --ft git-config -> tree-sitter-git-config.git
  -c, --clean          clean the local repo and update to the latest revision
  -h, --help           show this help message

EXAMPLES
  \$ ${ME} --ft groovy
  \$ ${ME} --ft git-config --clean
"

function clean() {
  if test -d "${LOCAL_REPO:-}" && git -C "${LOCAL_REPO:-}" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "${LOCAL_REPO}" clean -dffx
    git -C "${LOCAL_REPO}" fetch --all --progress --prune
    git -C "${LOCAL_REPO}" reset --hard origin/"${BRANCH}"
    printf '==> %s repo has been updated to the latest revision %s in %s\n' "${BIN_NAME}" "$( git -C "${LOCAL_REPO}" rev-parse --short=9 HEAD )" "${LOCAL_REPO}"
  else
    git clone "${REPO_URL}" "${LOCAL_REPO}"
    printf '==> %s repo has been cloned to %s\n' "${BIN_NAME}" "${LOCAL_REPO}"
  fi
}

# call `make nvim-install` for marslo forks (nvim + CLI build/install), else build()
function installts() {
  local _url; _url="$( git -C "${LOCAL_REPO}" remote get-url origin 2>/dev/null )"
  case "${_url}" in
    *marslo/${REPO_NAME}* ) command make -C "${LOCAL_REPO}" nvim-install ;;
    *                     ) build ;;
  esac
}

# shellcheck disable=SC2015
function build() {
  local _nvimso="${HOME}/.local/share/nvim/site/parser/${PARSER}.so"
  local _os; _os="$( uname )"
  local _cliso
  test 'Darwin' = "${_os}" && _cliso="${HOME}/.cache/tree-sitter/lib/${PARSER}.dylib" || _cliso="${HOME}/.cache/tree-sitter/lib/${PARSER}.so"

  tree-sitter generate
  tree-sitter build -o "${PARSER}.so"
  printf '==> %s parser has been built successfully in %s\n' "${PARSER}" "${LOCAL_REPO}/${PARSER}.so"
  test 'Darwin' = "${_os}" && { codesign --force --sign - "${PARSER}.so"; printf '==> %s parser codesigned successfully (%s.so)\n' "${PARSER}" "${PARSER}"; } || :

  mkdir -p "${_nvimso%/*}" "${_cliso%/*}"
  command cp -f "${PARSER}.so" "${_nvimso}"
  printf '==> %s parser for vim/nvim installed in %s\n' "${PARSER}" "${_nvimso}"

  tree-sitter build -o "${_cliso}"
  printf '==> %s parser for CLI installed in %s\n' "${PARSER}" "${_cliso}"
  test 'Darwin' = "${_os}" && { codesign --force --sign - "${_cliso}"; printf '==> %s parser for CLI codesigned successfully (%s)\n' "${PARSER}" "${_cliso}"; } || :
}

# verify
function verify() {
  command nvim --headless -u NONE -c "set rtp+=~/.local/share/nvim/site" -c "lua vim.treesitter.language.add('${PARSER}'); print('==> nvim OK')" -c "qa!"
}

function main() {
  pushd . >/dev/null || exit 1

  { "${CLEAN}" || ! test -d "${LOCAL_REPO}"; } && { clean || exit $?; }

  cd "${LOCAL_REPO}" || exit 1
  build || { echo "ERROR: Failed to build ${BIN_NAME} parser" >&2; exit 1; }
  printf '==> %s parser has been built successfully in %s\n' "${BIN_NAME}" "${LOCAL_REPO}"

  verify || { echo "ERROR: Failed to verify ${BIN_NAME} parser" >&2; exit 1; }
}

while test $# -gt 0; do
  case "${1}" in
    -f | --ft   ) test $# -ge 2 || { echo "ERROR: --ft requires a value" >&2; exit 1; }
                  FT="${2}"; shift 2 ;;
    --ft=*      ) FT="${1#*=}"; shift ;;
    -c | --clean) CLEAN=true; shift ;;
    -h | --help ) echo -e "${USAGE}" >&2; exit 0 ;;
    *           ) echo "ERROR: unknown option '${1}'" >&2; exit 1 ;;
  esac
done

test -n "${FT}" || { echo 'ERROR: --ft <filetype> is required' >&2; echo -e "${USAGE}" >&2; exit 1; }

# derive per-filetype paths (after arg parsing so they can use ${FT})
declare -r REPO_NAME="tree-sitter-${FT}"
declare -r LOCAL_REPO="${HERE}/${REPO_NAME}.git"
declare -r REPO_URL="https://git::@github.com/marslo/${REPO_NAME}.git"
declare -r PARSER="${SO_NAME[${FT}]:-${FT}}"
declare -r BIN_NAME="${REPO_NAME}"

main

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
