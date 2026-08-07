#!/usr/bin/env bash
#
# coc-fix.sh — re-apply the coc.nvim completion-resolve workaround.
#
# what: drop "data" from the advertised completionList.itemDefaults and set
#       applyKindSupport=false in build/index.js, so LSP servers (pyright) inline
#       per-item completion data again and completionItem/resolve returns
#       documentation/detail. see coc-pyright-completion-resolve-regression report.
# when: run after any coc update / :CocUpdate / git checkout that reverts the patch,
#       while upstream (>= 6c1cf016) still ships the regression. then :CocRestart.
#
# usage:
#   ./coc-fix.sh                 # apply (idempotent) to ~/.vim/plugged/coc.nvim
#   ./coc-fix.sh /path/to/coc    # apply to a custom coc.nvim dir
#   ./coc-fix.sh --git           # apply via `git apply coc-fix.patch` instead
#   ./coc-fix.sh --revert        # restore pristine build/index.js (git checkout)
#   ./coc-fix.sh --help
#
# env:
#   COC_NVIM_DIR   override the coc.nvim directory (same as arg 1)

set -uo pipefail

# assign then mark readonly separately so command-sub exit codes aren't masked
ME="$( basename "${0}" )"
SCRIPT_DIR="$( cd "$( dirname "${0}" )" && pwd )"
readonly ME SCRIPT_DIR
declare -r DEFAULT_COC_DIR="${HOME}/.vim/plugged/coc.nvim"
declare -r PATCH="${SCRIPT_DIR}/coc-fix.patch"

function info() { echo "[${ME}] ${1}" ; }
function die()  { echo "[${ME}] ✘ ${1}" >&2 ; exit 1 ; }

function usage() {
  # print the leading comment block (from line 3) until the first non-# line
  command awk 'NR>=3 { if ($0 !~ /^#/) exit; sub(/^# ?/, ""); print }' "${0}"
  exit 0
}

# text-based apply (whitespace/line tolerant, idempotent). echoes a STATUS word.
function applyWorkaround() {
  local target="${1}"
  python3 - "${target}" <<'PY'
import re, sys
f = sys.argv[1]
s = open(f, encoding='utf-8').read()
patched  = re.search(r'"insertTextMode"\s*\]\s*,\s*applyKindSupport:\s*false', s)
original = re.search(r'"insertTextMode"\s*,\s*"data"\s*\]\s*,\s*applyKindSupport:\s*true', s)
if patched and not original:
    print('already-patched'); sys.exit(0)
if not original:
    print('pattern-not-found'); sys.exit(3)
s = re.sub(r'("insertTextMode")\s*,\s*"data"(\s*\]\s*,\s*applyKindSupport:\s*)true',
           r'\1\2false', s, count=1)
open(f, 'w', encoding='utf-8').write(s)
print('applied')
PY
}

# ---- args ----
declare MODE='text'
declare COC_DIR="${COC_NVIM_DIR:-${DEFAULT_COC_DIR}}"
# shift-based loop: safe under `set -u` with zero args (macOS bash 3.2)
while test 0 -lt "${#}"; do
  case "${1}" in
    --help|-h ) usage ;;
    --git     ) MODE='git' ;;
    --revert  ) MODE='revert' ;;
    -*        ) die "unknown option: ${1} (see --help)" ;;
    *         ) COC_DIR="${1}" ;;
  esac
  shift
done

declare -r TARGET="${COC_DIR}/build/index.js"
test -d "${COC_DIR}" || die "coc.nvim dir not found: ${COC_DIR} (pass it as arg 1 or set COC_NVIM_DIR)"
test -f "${TARGET}"  || die "target not found: ${TARGET}"

# ---- revert ----
if test 'revert' = "${MODE}"; then
  declare -a revertCmd=( command git -C "${COC_DIR}" checkout -- build/index.js )
  "${revertCmd[@]}" || die "git checkout failed"
  info "reverted build/index.js to pristine — run :CocRestart"
  exit 0
fi

# ---- apply via git patch ----
if test 'git' = "${MODE}"; then
  test -f "${PATCH}" || die "patch not found next to script: ${PATCH}"
  declare -a checkCmd=( command git -C "${COC_DIR}" apply --reverse --check "${PATCH}" )
  if "${checkCmd[@]}" >/dev/null 2>&1; then
    info "already patched (git) — nothing to do. run :CocRestart if not yet restarted"
    exit 0
  fi
  declare -a applyCmd=( command git -C "${COC_DIR}" apply --whitespace=nowarn "${PATCH}" )
  "${applyCmd[@]}" || die "git apply failed (coc version drift?) — retry without --git for the text-based apply"
  info "applied via git patch — run :CocRestart"
  exit 0
fi

# ---- apply via text replacement (default) ----
STATUS="$( applyWorkaround "${TARGET}" )"
case "${STATUS}" in
  applied         ) info "workaround applied to ${TARGET} — run :CocRestart" ;;
  already-patched ) info "already patched — nothing to do" ;;
  pattern-not-found )
    die "capability block not found — coc.nvim likely changed build/index.js.
       check whether upstream already fixed it; otherwise patch manually:
         itemDefaults: [..., \"data\"]  ->  drop \"data\"
         applyKindSupport: true          ->  false" ;;
  * ) die "unexpected status: ${STATUS}" ;;
esac
