#!/usr/bin/env bash

set -euo pipefail

# per-host suffix, same convention as brewfile.sh
test 'iMarsloPro' = "$(hostname -f)" && SUFFIX=".$(hostname -f)" || SUFFIX=''

# resolve pipx: PATH first, then the current python's user-base bin
PYVER="$( python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")' )"
PIPX="$( command -v pipx || true )"
test -n "${PIPX}"  || PIPX="${HOME}/Library/Python/${PYVER}/bin/pipx"
test -x "${PIPX}"  || PIPX="${HOME}/.local/bin/pipx"

REQ="requirements${SUFFIX}.txt"     # pip snapshot        -> pip install -r
PIPX_JSON="pipx${SUFFIX}.json"      # pipx canonical      -> restore source of truth
PIPX_TXT="pipx${SUFFIX}.txt"        # pipx flat spec list -> xargs -n1 pipx install

# dump a command's stdout to FILE atomically (via FILE.new)
function dump() {
  local target="${1}"; shift
  local -a cmd=( "${@}" )
  if "${cmd[@]}" > "${target}.new"; then
    test -f "${target}" && rm -vf "${target}"
    mv -v "${target}.new" "${target}"
  else
    rm -f "${target}.new"
    return 1
  fi
}

# 1. pip  — full freeze of the homebrew python env
dump "${REQ}" python3 -m pip freeze

# 2. pipx — canonical json (keeps git URLs, versions, injected pkgs, pip_args)
dump "${PIPX_JSON}" "${PIPX}" list --json

# 3. pipx — flat spec list: package name or git+URL, one per line
python3 - "${PIPX_JSON}" "${PIPX_TXT}" <<'PY'
import json, sys
src, dst = sys.argv[1], sys.argv[2]
with open(src) as fh:
    venvs = json.load(fh).get('venvs', {})
specs = sorted( v['metadata']['main_package']['package_or_url'] for v in venvs.values() )
with open(dst, 'w') as fh:
    fh.write('\n'.join(specs) + '\n')
PY

printf 'pip  -> %s (%s pkgs)\n'      "${REQ}"                   "$( wc -l < "${REQ}" | tr -d ' ' )"
printf 'pipx -> %s + %s (%s apps)\n' "${PIPX_JSON}" "${PIPX_TXT}" "$( wc -l < "${PIPX_TXT}" | tr -d ' ' )"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
