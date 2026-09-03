#!/usr/bin/env bash

set -euo pipefail

# print a copy-pasteable rc block: prefer this build, fall back to homebrew/system
printSnippet() {
cat <<'SNIPPET'
# bash-completion: prefer locally-built 2.12+, fall back to homebrew/system
for _bc in "${HOME}/.local/opt/bash-completion/share/bash-completion/bash_completion" \
           "${HOMEBREW_PREFIX:-/opt/homebrew}/share/bash-completion/bash_completion" \
           /usr/local/share/bash-completion/bash_completion \
           /usr/share/bash-completion/bash_completion \
           /etc/bash_completion; do
  test -r "${_bc}" && { source "${_bc}"; break; }
done
unset -v _bc
SNIPPET
}

# after install, tell the user how to wire the shell rc, based on its current state
printRcHint() {
  local marker='local/opt/bash-completion'          # signature of this build in an rc
  local -a rcFiles=( "${HOME}/.bashrc" "${HOME}/.bash_profile" "${HOME}/.bash_login" "${HOME}/.profile" )
  local rc hit

  if test 'Darwin' = "$( uname )"; then
    rc="${HOME}/.bash_profile"
  else
    rc="${HOME}/.bashrc"
  fi

  echo
  echo '==> shell setup — make interactive shells load this build:'
  echo

  # case 0: an rc already references this build
  if command grep -qs "${marker}" "${rcFiles[@]}" 2>/dev/null; then
    echo '    already wired to this build; open a new shell to pick it up:'
    echo '        exec bash -l'
    return 0
  fi

  # case 1: an rc already loads an older/system bash-completion -> change it
  hit="$( command grep -lsE 'bash[-_]completion' "${rcFiles[@]}" 2>/dev/null | head -1 || true )"
  if test -n "${hit}"; then
    echo "    [old version] system bash-completion is loaded in: ${hit}"
    echo '    -> replace that source line with the block below, then run: exec bash -l'
    echo
    echo '    current:'
    command grep -nE 'bash[-_]completion' "${hit}" | command sed 's/^/        /' || true
    echo
    echo '    replace with:'
    printSnippet | command sed 's/^/        /'
    return 0
  fi

  # case 2: no bash-completion anywhere -> add it
  echo "    [not present] no bash-completion setup found; append the block below to: ${rc}"
  echo '    then run: exec bash -l'
  echo
  printSnippet | command sed 's/^/        /'
}

PREFIX="${HOME}/.local/opt/bash-completion"
WORK="$( mktemp -d )"; trap 'rm -rf "${WORK}"' EXIT

# resolve latest release dist tarball (ships ./configure)
URL="$( curl -fsSL https://api.github.com/repos/scop/bash-completion/releases/latest | command grep -oE 'https://[^"]+/bash-completion-[0-9.]+\.tar\.xz' | head -1 )"
test -n "${URL}" || { echo 'no .tar.xz asset found — use the git fallback' >&2; exit 1; }
echo "==> ${URL##*/}"

curl -fsSL "${URL}" | tar -xJf - -C "${WORK}"
cd "${WORK}"/bash-completion-*/
./configure --prefix="${PREFIX}" >/dev/null
make install >/dev/null

MAIN="${PREFIX}/share/bash-completion/bash_completion"
command grep -q '_comp_initialize' "${MAIN}" && echo "OK: ${MAIN}"

printRcHint

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
