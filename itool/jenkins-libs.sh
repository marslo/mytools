#!/usr/bin/env bash
# =============================================================================
#      FileName : jenkins-libs.sh
#        Author : marslo
#       Created : 2025-02-16 17:52:35
#    LastChange : 2026-08-10 23:10:26
#   Description : download + extract the latest jenkins war and a fixed set of
#                 plugins into /opt/jenkins, maintaining `latest` symlinks.
#         Usage : jenkins-libs.sh [--lts] [--ln] [--dryrun] [-p PATH]
#                   --lts      download the latest LTS war (default: weekly)
#                   --ln       refresh ~/.groovy/lib: prune dangling /opt/jenkins links, then symlink core war + plugin *.jar
#                   --dryrun   print planned actions only; install nothing
#                   -p PATH    install root for war + plugins (default: /opt/jenkins)
# =============================================================================

set -euo pipefail

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

# -------------------------------- constants ---------------------------------
declare -r  _DEFAULT_ROOT='/opt/jenkins'
declare     JENKINS_ROOT="${_DEFAULT_ROOT}"        # install root; overridable via -p/--path
declare     PLUGIN_ROOT="${JENKINS_ROOT}/plugins"  # re-derived after arg parse (see resolvePaths)
declare -r  GROOVY_LIB="${HOME}/.groovy/lib"
declare     LOG_ROOT="${JENKINS_ROOT}/logs"        # re-derived after arg parse (see resolvePaths)
declare -r  UC_BASE='https://updates.jenkins.io'

# local dir name → plugin list (hardcoded)
declare -ra PLUGINS=( badge credentials git pipeline-job workflow-support )
# override where the local dir name differs from the jenkins artifact id
declare -rA PLUGIN_ARTIFACT=( [pipeline-job]='workflow-job' )

# -------------------------------- options -----------------------------------
declare WAR_CHANNEL='weekly'   # weekly | lts
declare DO_LINK=false          # --ln
declare DRY_RUN=false          # --dryrun
declare WAR_VERSION=''         # resolved core version
declare UC_JSON=''             # cached update-center.actual.json path
declare LOG_FILE=''            # /opt/jenkins/logs/[dryrun-]<yyMMDDhhmmss>.log (set in main)

# --------------------------------- usage ------------------------------------
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
{ test 'bash' = "${ME}" || test -z "${ME}" ; } && ME='jenkins-libs.sh'
# shellcheck disable=SC2155
declare USAGE="NAME
  download + extract the latest jenkins war and a fixed set of plugins into $(c 0Wi)\${JENKINS_ROOT}$(c), maintaining $(c 0Wi)\`latest\`;$(c) symlinks.

USAGE
  $(c 0Ys)${ME} $(c 0G)[OPTIONS]$(c)

OPTIONS
  $(c 0G)--lts$(c)                     download the latest Jenkins LTS war $(c 0Wi)(default: weekly)$(c)
  $(c 0G)--ln$(c)                      refresh $(c 0Mi)${GROOVY_LIB}/$(c) (created if missing): prune dangling $(c 0Mi)\${JENKINS_ROOT}$(c) links, then symlink core war + plugin *.jar
  $(c 0G)--dryrun$(c)                  print planned actions only; download/extract/link nothing
  $(c 0G)-p$(c), $(c 0G)--path $(c 0Mi)DESTINATION$(c)    install root for war + plugins $(c 0Wi)(default: ${_DEFAULT_ROOT})$(c)
  $(c 0G)-h$(c), $(c 0G)--help$(c)                show this help

EXAMPLES
  $(c 0Wdi)# download the latest LTS jenkins war and refresh ~/.groovy/lib symlinks$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--lts --ln$(c)

  $(c 0Wdi)# download the latest weekly jenkins in dryrun mode (no changes made)$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--dryrun$(c)

  $(c 0Wdi)# install into a custom root$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--lts --path $(c 0Mi)/tmp/jenkins$(c)
"

function usage() { echo -e "${USAGE}" >&2; }

# -------------------------------- helpers -----------------------------------
# external binaries are invoked via `command` to bypass any alias/function
# shadowing; only shell builtins (test/printf/shopt/...) are called bare.

# terminal-only palette (empty when bash-colors is absent); never written to LOG_FILE
declare _NOR _CI _CG _CB _CR
_NOR="$(c 0)"    # italic body
_CI="$(c 0i)"    # italic body
_CG="$(c 0G)"    # green: names / versions
_CB="$(c 0Bui)"  # blue underline italic: paths / urls
_CR="$(c)"       # reset

# colored badge for terminal output; e.g. show --info --bg 'INFO'
function show() {
  local layer='38' color='151'
  local -a args=()
  for arg in "${@}"; do
    case "${arg}" in
      --fg    ) layer='38'       ;;
      --bg    ) layer='30;48'    ;;
      --info  ) color='151'      ;;
      --warn  ) color='178'      ;;
      --error ) color='174'      ;;
      --note  ) color='117'      ;;
      -*      ) printf "unknown option in show(): '%s'\n" "${arg}" >&2 ;;
      *       ) args+=( "${arg}" ) ;;
    esac
  done
  printf "\033[0;%s;5;%sm%s\033[0m" "${layer}" "${color}" "${args[*]}"
}

# highlight key tokens for the terminal only (versions/names green, paths/urls blue, connective words italic). classifies whole tokens → no nested-ANSI; LOG_FILE never sees this.
function hl() {
  local s="${*}" indent rest
  indent="${s%%[![:space:]]*}"                                   # leading whitespace (preserve indent)
  rest="${s#"${indent}"}"
  local -a toks=()
  read -ra toks <<< "${rest}" || true                            # split on spaces without globbing
  local out='' tok
  for tok in "${toks[@]}"; do
    case "${tok}" in
      http://*|https://*|/*|~/* ) out+="${_CB}${tok}${_CR} "  ;;  # paths / urls
      \[*\]                     ) out+="${_CG}${tok}${_CR} "  ;;  # [name] / [DRYRUN]
      [0-9]*.[0-9]*|v[0-9]*     ) out+="${_CG}${tok}${_CR} "  ;;  # versions
      *                         ) out+="${_NOR}${tok}${_CR} " ;;  # normal body
    esac
  done
  printf '%s%s' "${indent}" "${out% }"
}

# terminal gets a colored badge + highlighted body; LOG_FILE stays plain (no color) log to stderr and, once LOG_FILE is set, append to it (never aborts the run)
function log() {
  echo -e "$( show --info --bg 'INFO' ) $( hl "${*}" )" >&2
  if test -n "${LOG_FILE}"; then printf '>> %s\n' "${*}" >> "${LOG_FILE}" || true; fi
}
function die() {
  echo -e "$( show --bg --error 'ERROR' ) $( hl "${*}" )" >&2
  if test -n "${LOG_FILE}"; then printf 'error: %s\n' "${*}" >> "${LOG_FILE}" || true; fi
  exit 1
}
# terminal gets a ✓ badge; LOG_FILE stays plain
function ok() {
  echo -e "$( show --bg --note ' ✓ ' ) $( hl "${*}" )" >&2
  if test -n "${LOG_FILE}"; then printf '>> %s\n' "${*}" >> "${LOG_FILE}" || true; fi
}
# append a line to LOG_FILE only (no stderr); for per-file audit detail
function logf() {
  if test -n "${LOG_FILE}"; then printf '>> %s\n' "${*}" >> "${LOG_FILE}" || true; fi
}

# update-center metadata channel: stable for lts, current for weekly
function ucMeta() {
  test 'lts' = "${WAR_CHANNEL}" && printf 'stable' || printf 'current'
}

function cleanup() {
  if test -n "${UC_JSON}"; then command rm -f "${UC_JSON}"; fi
}

# run a mutating command (via `command`), or just print it under --dryrun
function act() {
  if "${DRY_RUN}"; then log "[DRYRUN] ${*}"; else command "${@}"; fi
}

# read a single MANIFEST.MF value from a war/hpi/jpi archive
# usage: manifestValue <archive> <key>
function manifestValue() {
  local archive="${1}"
  local key="${2}"
  local value
  value="$( command unzip -p "${archive}" META-INF/MANIFEST.MF 2>/dev/null |
            command tr -d '\r' |
            command grep -m1 -E "^${key}:" |
            command sed -E "s/^${key}:[[:space:]]*//" )" || true
  printf '%s' "${value}"
}

# -------------------------------- war ---------------------------------------
# latest core version for the selected channel; empty on failure
function latestCore() {
  local ver
  ver="$( command curl -fsSL --max-time 30 "${UC_BASE}/$(ucMeta)/latestCore.txt" 2>/dev/null | command tr -d '[:space:]' )" || true
  printf '%s' "${ver}"
}

function installWar() {
  local ver dest tmp
  log "resolving ${WAR_CHANNEL} core version ..."
  ver="$( latestCore )"
  test -n "${ver}" || die 'unable to determine jenkins core version'

  dest="${JENKINS_ROOT}/${ver}"
  WAR_VERSION="${ver}"

  if test -d "${dest}/WEB-INF"; then
    log "jenkins ${ver} already extracted; skip download"
  elif "${DRY_RUN}"; then
    log "[DRYRUN] would download ${UC_BASE}/download/war/${ver}/jenkins.war"
    log "[DRYRUN] would extract  jenkins.war -> ${dest}/"
  else
    tmp="$( command mktemp "${TMPDIR:-/tmp}/jenkins-war.XXXXXX" )"
    log "downloading jenkins ${ver} war ..."
    command curl -fL --progress-bar --max-time 1800 -o "${tmp}" "${UC_BASE}/download/war/${ver}/jenkins.war"
    command mkdir -p "${dest}"
    command mv -f "${tmp}" "${dest}/jenkins.war"
    log "extracting war -> ${dest}"
    command unzip -o -q "${dest}/jenkins.war" -d "${dest}"
  fi

  act ln -sfn "${ver}" "${JENKINS_ROOT}/latest"
  log "jenkins ${ver} (${WAR_CHANNEL}); ${JENKINS_ROOT}/latest -> ${ver}"
}

# -------------------------------- plugins -----------------------------------
# fetch update-center.actual.json once into UC_JSON (cache in the caller's shell) must be called outside command substitution so the assignment persists
function ensureUcJson() {
  if test -z "${UC_JSON}"; then
    UC_JSON="$( command mktemp "${TMPDIR:-/tmp}/uc-actual.XXXXXX.json" )"
    log "fetching update-center metadata ($( ucMeta )) ..."
    command curl -fsSL --max-time 90 -o "${UC_JSON}" "${UC_BASE}/$( ucMeta )/update-center.actual.json" || die 'cannot fetch update-center.actual.json'
  fi
}

# latest published version of an artifact from the cached metadata; empty on failure
function remotePluginVersion() {
  local artifact="${1}"
  local ver
  ver="$( command jq -r --arg p "${artifact}" '.plugins[$p].version // empty' "${UC_JSON}" 2>/dev/null )" || true
  printf '%s' "${ver}"
}

# remove dangling symlinks under ~/.groovy/lib that point into /opt/jenkins.
function pruneStaleLinks() {
  local link target count=0
  test -d "${GROOVY_LIB}" || return 0
  shopt -s nullglob
  for link in "${GROOVY_LIB}"/*; do
    test -L "${link}" || continue                # symlinks only
    target="$( command readlink "${link}" )"
    case "${target}" in
      "${JENKINS_ROOT}"/* )          ;;          # only links we manage
      *                   ) continue ;;
    esac
    if test -e "${link}"; then continue; fi      # target exists → keep
    if test 'true' = "${DRY_RUN}"; then          # remove exactly one dangling link
      log "  [DRYRUN] unlink ${link}"
    else
      command unlink "${link}"
      logf "  unlink ${link}"                    # detail to log file only
    fi
    count=$(( count + 1 ))
  done
  shopt -u nullglob
  log "  pruned ${count} stale link(s)"
}

# symlink every *.jar in <libDir> into ~/.groovy/lib/
function linkDir() {
  local libDir="${1}"
  local label="${libDir#"${JENKINS_ROOT}"/}"
  local jar base count=0
  if test 'true' = "${DRY_RUN}"; then
    log "  [DRYRUN] would symlink ${label}/*.jar -> ${GROOVY_LIB}/"
    return 0
  fi
  test -d "${libDir}" || { log "  skip (missing) ${label}"; return 0; }
  shopt -s nullglob
  for jar in "${libDir}"/*.jar; do
    base="$( command basename "${jar}" )"
    command ln -sfn "${jar}" "${GROOVY_LIB}/${base}"
    logf "  link ${GROOVY_LIB}/${base}"          # detail to log file only
    count=$(( count + 1 ))
  done
  shopt -u nullglob
  log "  linked ${count} jar(s) from ${label}"
}

# refresh ~/.groovy/lib: prune dead links, then (re)link core war + plugin jars
function relinkLibs() {
  log 'refreshing ~/.groovy/lib symlinks ...'
  act mkdir -p "${GROOVY_LIB}"
  pruneStaleLinks
  linkDir "${JENKINS_ROOT}/latest/WEB-INF/lib"
  local name
  for name in "${PLUGINS[@]}"; do
    linkDir "${PLUGIN_ROOT}/${name}/latest/WEB-INF/lib"
  done
}

# install one plugin: prefer the war-bundled hpi, else download the latest
function installPlugin() {
  local name="${1}"
  local artifact warHpi ver dest src source tmp=''
  artifact="${PLUGIN_ARTIFACT[${name}]:-${name}}"
  warHpi="${JENKINS_ROOT}/latest/WEB-INF/detached-plugins/${artifact}.hpi"

  if test -f "${warHpi}"; then
    source='war'
    src="${warHpi}"
    ver="$( manifestValue "${warHpi}" 'Plugin-Version' )"
  else
    source='download'
    ensureUcJson
    ver="$( remotePluginVersion "${artifact}" )"
  fi
  test -n "${ver}" || die "cannot resolve version for plugin '${name}' (artifact '${artifact}')"

  dest="${PLUGIN_ROOT}/${name}/${ver}"

  if test -d "${dest}/WEB-INF"; then
    log "[${name}] ${ver} already present (${source}); skip"
  elif test 'true' = "${DRY_RUN}"; then
    if test 'download' = "${source}"; then
      log "[${name}] [DRYRUN] would download ${UC_BASE}/download/plugins/${artifact}/${ver}/${artifact}.hpi"
    fi
    log "[${name}] [DRYRUN] would extract ${artifact}.hpi (${source}) -> ${dest}/"
  else
    if test 'download' = "${source}"; then
      tmp="$( command mktemp "${TMPDIR:-/tmp}/${artifact}-hpi.XXXXXX" )"
      log "[${name}] downloading ${artifact} ${ver} ..."
      command curl -fL --progress-bar --max-time 600 -o "${tmp}" "${UC_BASE}/download/plugins/${artifact}/${ver}/${artifact}.hpi"
      src="${tmp}"
    fi
    log "[${name}] extracting -> ${dest}"
    command mkdir -p "${dest}"
    command unzip -o -q "${src}" -d "${dest}"
    if test -n "${tmp}"; then command rm -f "${tmp}"; fi
  fi

  act ln -sfn "${ver}" "${PLUGIN_ROOT}/${name}/latest"
  log "[${name}] ${ver} (${source}); latest -> ${ver}"
}

# -------------------------------- flow --------------------------------------
function parseArgs() {
  while test ${#} -gt 0; do
    case "${1}" in
      --lts                ) WAR_CHANNEL='lts' ;;
      --ln                 ) DO_LINK=true      ;;
      --dryrun | --dry-run ) DRY_RUN=true      ;;
      -p | --path          ) test -n "${2:-}" || die '--path requires a directory argument'; JENKINS_ROOT="${2}"; shift ;;
      -h | --help          ) usage; exit 0     ;;
      *                    ) usage; die "unknown argument: ${1}" ;;
    esac
    shift
  done
}

# derive paths under the (possibly --path-overridden) install root
function resolvePaths() {
  PLUGIN_ROOT="${JENKINS_ROOT}/plugins"
  LOG_ROOT="${JENKINS_ROOT}/logs"
}

function main() {
  parseArgs "${@}"
  resolvePaths
  trap cleanup EXIT
  command mkdir -p "${LOG_ROOT}"
  if "${DRY_RUN}"; then
    LOG_FILE="${LOG_ROOT}/dryrun-$( command date +'%y%m%d%H%M%S' ).log"
  else
    LOG_FILE="${LOG_ROOT}/$( command date +'%y%m%d%H%M%S' ).log"
  fi
  log "logging to ${LOG_FILE}"
  if "${DRY_RUN}"; then log '=== dryrun: no changes will be made ==='; fi
  command -v curl  >/dev/null || die 'curl not found'
  command -v unzip >/dev/null || die 'unzip not found'
  command -v jq    >/dev/null || die 'jq not found'
  act mkdir -p "${JENKINS_ROOT}" "${PLUGIN_ROOT}"

  installWar
  local p
  for p in "${PLUGINS[@]}"; do
    installPlugin "${p}"
  done

  if "${DO_LINK}"; then relinkLibs; fi

  ok "done. jenkins=${WAR_VERSION} channel=${WAR_CHANNEL} link=${DO_LINK} dryrun=${DRY_RUN}"
}

main "${@}"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
