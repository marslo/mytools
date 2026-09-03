#!/usr/bin/env bash
# =============================================================================
#      FileName : jenkins-libs.sh
#        Author : marslo
#       Created : 2025-02-16 17:52:35
#    LastChange : 2026-08-14 01:22:06
#   Description : download + extract the latest jenkins war, a fixed set of plugins, jenkins-core reference jars (.jar/-sources/-javadoc), and cloudbees/maven extension jars into /opt/jenkins, maintaining `latest` symlinks.
#         Usage : jenkins-libs.sh [--lts] [--ln] [--dryrun] [-p PATH] [-P PLUGIN ...] [-e ARTIFACT ...]
#                   --lts             download the latest LTS war (default: weekly)
#                   --ln              refresh ~/.groovy/lib: prune dangling /opt/jenkins links, then symlink war libs + jenkins-core + plugin + extension *.jar
#                   --dryrun          print planned actions only; install nothing
#                   -p PATH           install root for war + plugins + core + extensions (default: /opt/jenkins)
#                   -P, --plugin      extra jenkins plugin (repeatable; merged with the default list, deduped)
#                   -e, --extensions  extra maven extension artifact (repeatable; merged with the default list, deduped)
#         Layout : <root>/<ver>/{WEB-INF/, jenkins.war, core/jenkins-core-<ver>{,-sources,-javadoc}.jar}
#                  <root>/extensions/<artifact>/<ver>/<artifact>-<ver>{,-sources,-javadoc}.jar
# =============================================================================

set -euo pipefail

# require bash >= 4.3 (associative arrays + namerefs used throughout)
if test "${BASH_VERSINFO[0]:-0}" -lt 4 || { test "${BASH_VERSINFO[0]}" -eq 4 && test "${BASH_VERSINFO[1]:-0}" -lt 3; }; then
  echo "error: bash >= 4.3 required (found ${BASH_VERSION:-unknown}); on macOS install & run via homebrew bash (brew install bash)" >&2
  exit 1
fi

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

# -------------------------------- constants ---------------------------------
declare -r  _DEFAULT_ROOT='/opt/jenkins'
declare     JENKINS_ROOT="${_DEFAULT_ROOT}"                     # install root; overridable via -p/--path
declare     PLUGIN_ROOT="${JENKINS_ROOT}/plugins"               # set in resolvePaths
declare -r  GROOVY_LIB="${HOME}/.groovy/lib"
declare     LOG_ROOT="${JENKINS_ROOT}/logs"                     # set in resolvePaths
declare -r  UC_BASE='https://updates.jenkins.io'
declare -r  CORE_BASE='https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-core'  # maven repo for jenkins-core reference jars
declare -r  MAVEN_BASE='https://repo1.maven.org/maven2'         # maven central for extension reference jars
declare -r  JENKINS_MVN='https://repo.jenkins-ci.org/public'    # jenkins-ci maven repo for bundled-jar docs
declare -r  EXT_GROUP='com/cloudbees'                           # default maven group for extensions
declare     EXT_ROOT="${JENKINS_ROOT}/extensions"               # set in resolvePaths

# default plugins (merged with -P, deduped)
declare -a  PLUGINS=( badge credentials git pipeline-job workflow-support )
# local-dir name → jenkins artifact id
declare -rA PLUGIN_ARTIFACT=( [pipeline-job]='workflow-job' )

# default extensions (merged with -e, deduped)
declare -a  EXTENSIONS=( groovy-cps )
# per-artifact maven group overrides
declare -rA EXTENSION_GROUP=()

# -------------------------------- options -----------------------------------
declare WAR_CHANNEL='weekly'          # weekly | lts
declare DO_LINK=false                 # --ln
declare CLEAN=false                   # --clean : remove managed links + downloaded content, then exit
declare DO_DOCS=false                 # --sources : also fetch reference doc jars for war + plugin lib jars
declare -a DOC_TYPES=( '-sources' )   # doc jar types fetched under --sources; --javadoc appends '-javadoc'
declare DRY_RUN=false                 # --dryrun
declare WAR_VERSION=''                # resolved core version
declare UC_JSON=''                    # cached update-center.actual.json path
declare LOG_FILE=''                   # /opt/jenkins/logs/[dryrun-]<yyMMDDhhmmss>.log (set in main)

# --------------------------------- usage ------------------------------------
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
{ test 'bash' = "${ME}" || test -z "${ME}" ; } && ME='jenkins-libs.sh'
# shellcheck disable=SC2155
declare USAGE="DESCRIPTION
  install jenkins war + plugins + core/extension jars into $(c 0Wi)\${JENKINS_ROOT}$(c) with $(c 0Wi)\`latest\`$(c) symlinks.

USAGE
  $(c 0Ys)${ME} $(c 0G)[OPTIONS]$(c)

OPTIONS
  $(c 0G)--lts$(c)                      download the latest Jenkins LTS war $(c 0Wi)(default: weekly)$(c)
  $(c 0G)--ln$(c)                       refresh $(c 0Mi)${GROOVY_LIB}/$(c) (created if missing):
                             prune dangling $(c 0Mi)\${JENKINS_ROOT}$(c) links, then symlink $(c 0Wi)war libs$(c) + $(c 0Wi)jenkins-core$(c) + $(c 0Wi)plugin$(c) + $(c 0Wi)extension *.jar$(c)
  $(c 0G)--sources$(c)                  fetch $(c 0Wi)-sources.jar$(c) for war + plugin $(c 0Wi)WEB-INF/lib$(c) jars $(c 0Wi)(binary-only otherwise; resolved via each jar's pom.properties)$(c)
  $(c 0G)--javadoc$(c)                  also fetch $(c 0Wi)-javadoc.jar$(c) $(c 0Wi)(implies --sources)$(c)
  $(c 0G)--dryrun$(c)                   print planned actions only; download/extract/link nothing
  $(c 0G)--clean$(c)                    remove managed $(c 0Mi)${GROOVY_LIB}$(c) links + downloaded content under $(c 0Wi)\${JENKINS_ROOT}$(c), then exit $(c 0Wi)(respects --dryrun; keeps the script)$(c)
  $(c 0G)-P$(c), $(c 0G)--plugin $(c 0Mi)PLUGIN$(c)        extra jenkins plugin $(c 0Wi)(repeatable; default list [$(c 0Mi)${PLUGINS[*]}$(c 0Wi)], deduped)$(c)
  $(c 0G)-e$(c), $(c 0G)--extensions $(c 0Mi)ARTIFACT$(c)  extra maven extension artifact $(c 0Wi)(repeatable; default list [$(c 0Mi)${EXTENSIONS[*]}$(c 0Wi)], deduped)$(c)
  $(c 0G)-p$(c), $(c 0G)--path $(c 0Mi)DESTINATION$(c)     install root for war + plugins + core + extensions $(c 0Wi)(default: ${_DEFAULT_ROOT})$(c)
  $(c 0G)-h$(c), $(c 0G)--help$(c)                 show this help

EXAMPLES
  $(c 0Wdi)# download the latest LTS jenkins war and refresh ~/.groovy/lib symlinks$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--lts --ln$(c)

  $(c 0Wdi)# download the latest weekly jenkins in dryrun mode (no changes made)$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--dryrun$(c)

  $(c 0Wdi)# install into a custom root$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--lts --path $(c 0Mi)/tmp/jenkins$(c)

  $(c 0Wdi)# add extra plugins + extension artifacts (merged with the defaults) and link into ~/.groovy/lib$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--ln -P $(c 0Mi)ansicolor $(c 0Gi)-e $(c 0Mi)workflow-step-api$(c)
"

function usage() { echo -e "${USAGE}" >&2; }

# -------------------------------- helpers -----------------------------------
# external binaries invoked via `command`; builtins called bare.

# terminal color palette
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
      --fg    ) layer='38'         ;;
      --bg    ) layer='30;48'      ;;
      --info  ) color='151'        ;;
      --warn  ) color='178'        ;;
      --error ) color='174'        ;;
      --note  ) color='117'        ;;
      -*      ) printf "unknown option in show(): '%s'\n" "${arg}" >&2 ;;
      *       ) args+=( "${arg}" ) ;;
    esac
  done
  printf "\033[0;%s;5;%sm%s\033[0m" "${layer}" "${color}" "${args[*]}"
}

# highlight tokens: versions/names green, paths/urls blue
function hl() {
  local s="${*}" indent rest
  indent="${s%%[![:space:]]*}"                                    # leading whitespace (preserve indent)
  rest="${s#"${indent}"}"
  local -a toks=()
  read -ra toks <<< "${rest}" || true                             # split on spaces without globbing
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

# INFO badge to stderr; plain line to LOG_FILE
function log() {
  echo -e "$( show --info --bg 'INFO' ) $( hl "${*}" )" >&2
  if test -n "${LOG_FILE}"; then printf '>> %s\n' "${*}" >> "${LOG_FILE}" || true; fi
}
function die() {
  echo -e "$( show --bg --error 'ERROR' ) $( hl "${*}" )" >&2
  if test -n "${LOG_FILE}"; then printf 'error: %s\n' "${*}" >> "${LOG_FILE}" || true; fi
  exit 1
}
# success badge to stderr; plain line to LOG_FILE
function ok() {
  echo -e "$( show --bg --note ' ✓ ' ) $( hl "${*}" )" >&2
  if test -n "${LOG_FILE}"; then printf '>> %s\n' "${*}" >> "${LOG_FILE}" || true; fi
}
# append to LOG_FILE only
function logf() { if test -n "${LOG_FILE}"; then printf '>> %s\n' "${*}" >> "${LOG_FILE}" || true; fi; }
# update-center metadata channel: stable for lts, current for weekly
function ucMeta() { test 'lts' = "${WAR_CHANNEL}" && printf 'stable' || printf 'current'; }
function clean() { if test -n "${UC_JSON}"; then command rm -f "${UC_JSON}"; fi; }
# run a command, or print it under --dryrun
function act() { if "${DRY_RUN}"; then log "[DRYRUN] ${*}"; else command "${@}"; fi; }

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

# -------------------------------- core --------------------------------------
# download jenkins-core .jar/-sources/-javadoc into ${JENKINS_ROOT}/<ver>/core
function installCore() {
  local ver="${WAR_VERSION}"
  test -n "${ver}" || { log 'skip core jars: core version unresolved'; return 0; }
  local dest="${JENKINS_ROOT}/${ver}/core"
  local repo="${CORE_BASE}/${ver}"
  local type url jar
  if "${DRY_RUN}"; then
    for type in '' '-sources' '-javadoc'; do
      log "[DRYRUN] would download ${repo}/jenkins-core-${ver}${type}.jar -> ${dest}/"
    done
    return 0
  fi
  command mkdir -p "${dest}"
  for type in '' '-sources' '-javadoc'; do
    url="${repo}/jenkins-core-${ver}${type}.jar"
    jar="${dest}/jenkins-core-${ver}${type}.jar"
    log "downloading jenkins-core ${ver}${type} ..."
    if ! command curl -fL --progress-bar --max-time 600 -o "${jar}" "${url}"; then
      command rm -f "${jar}"                       # drop partial/empty file
      log "WARN: cannot download ${url} (skipped)"
    fi
  done
}

# ------------------------------ extensions ----------------------------------
# latest released version of a maven artifact from its metadata; empty on failure
function latestMavenVersion() {
  local group="${1}" artifact="${2}" ver
  ver="$( command curl -fsSL --max-time 30 "${MAVEN_BASE}/${group}/${artifact}/maven-metadata.xml" 2>/dev/null |
          sed -nE 's:.*<release>(.*)</release>.*:\1:p' |
          command tr -d '[:space:]'
        )" || true
  printf '%s' "${ver}"
}

# download an extension's .jar/-sources/-javadoc into ${EXT_ROOT}/<artifact>/<ver>, point latest
function installExtension() {
  local artifact="${1}"
  local group="${EXTENSION_GROUP[${artifact}]:-${EXT_GROUP}}"
  local ver dest repo type url jar
  ver="$( latestMavenVersion "${group}" "${artifact}" )"
  test -n "${ver}" || { log "WARN: cannot resolve version for extension '${artifact}' (group ${group}); skipped"; return 0; }
  dest="${EXT_ROOT}/${artifact}/${ver}"
  repo="${MAVEN_BASE}/${group}/${artifact}/${ver}"
  if "${DRY_RUN}"; then
    for type in '' '-sources' '-javadoc'; do
      log "[DRYRUN] would download ${repo}/${artifact}-${ver}${type}.jar -> ${dest}/"
    done
    log "[DRYRUN] would link ${EXT_ROOT}/${artifact}/latest -> ${ver}"
    return 0
  fi
  command mkdir -p "${dest}"
  for type in '' '-sources' '-javadoc'; do
    url="${repo}/${artifact}-${ver}${type}.jar"
    jar="${dest}/${artifact}-${ver}${type}.jar"
    log "downloading extension ${artifact} ${ver}${type} ..."
    if ! command curl -fL --progress-bar --max-time 600 -o "${jar}" "${url}"; then
      command rm -f "${jar}"                       # drop partial/empty file
      log "WARN: cannot download ${url} (skipped)"
    fi
  done
  command ln -sfn "${ver}" "${EXT_ROOT}/${artifact}/latest"
  log "extension ${artifact} ${ver}; ${EXT_ROOT}/${artifact}/latest -> ${ver}"
}

# download every extension in the list
function installExtensions() {
  local a
  for a in "${EXTENSIONS[@]}"; do
    installExtension "${a}"
  done
}

# ---------------------------- bundled-jar docs ------------------------------

# echo "groupId artifactId version" for a jar, from the pom.properties whose
# artifactId matches the filename (empty if none)
function resolveGav() {
  local jar="${1}" base aid ver pp a g
  base="$( command basename "${jar}" .jar )"
  aid="${base%%-[0-9]*}"                                            # artifactId = up to the first -<digit>
  ver="${base#"${aid}-"}"                                           # version    = the remainder
  { test -n "${aid}" && test "${ver}" != "${base}"; } || return 0   # no version boundary → skip
  while IFS= read -r pp; do                                         # pick the pom whose artifactId matches
    a="$( command unzip -p "${jar}" "${pp}" 2>/dev/null | command tr -d '\r' | command sed -nE 's/^artifactId=//p' )"
    if test "${a}" = "${aid}"; then
      g="$( command unzip -p "${jar}" "${pp}" 2>/dev/null | command tr -d '\r' | command sed -nE 's/^groupId=//p' )"
      test -n "${g}" && { printf '%s %s %s' "${g}" "${aid}" "${ver}"; return 0; }
    fi
  done < <( command unzip -Z1 "${jar}" 'META-INF/maven/*/pom.properties' 2>/dev/null )
}

# jenkins-ci groups → jenkins repo; else maven central
function repoForGroup() {
  case "${1}" in
    org.jenkins-ci*|io.jenkins*|org.jvnet.hudson* ) printf '%s' "${JENKINS_MVN}" ;;
    *                                             ) printf '%s' "${MAVEN_BASE}"  ;;
  esac
}

# fetch DOC_TYPES jars next to each jar in <libDir>
function fetchLibDocs() {
  local libDir="${1}"
  local label="${libDir#"${JENKINS_ROOT}"/}"
  test -d "${libDir}" || { log "  skip docs (missing) ${label}"; return 0; }
  local jar base gav g a v repo type out url code count=0 skipped=0
  shopt -s nullglob
  for jar in "${libDir}"/*.jar; do
    case "${jar}" in *-sources.jar | *-javadoc.jar ) continue ;; esac
    base="$( command basename "${jar}" .jar )"
    gav="$( resolveGav "${jar}" )"
    test -n "${gav}" || { logf "  skip ${base}: no maven coords (no pom.properties)"; skipped=$(( skipped + 1 )); continue; }
    read -r g a v <<< "${gav}"
    repo="$( repoForGroup "${g}" )/${g//.//}/${a}/${v}"
    for type in "${DOC_TYPES[@]}"; do
      out="${libDir}/${base}${type}.jar"
      test -f "${out}" && continue                       # skip if already present
      url="${repo}/${a}-${v}${type}.jar"
      if "${DRY_RUN}"; then log "  [DRYRUN] would download ${url}"; continue; fi
      if code="$( command curl -fsSL --max-time 300 -o "${out}" -w '%{http_code}' "${url}" 2>/dev/null )"; then
        logf "  docs: ${out##*/}"
        count=$(( count + 1 ))
      else
        command rm -f "${out}"                           # drop partial/404
        log  "  $(c 0Y)skip$(c 0i): ${a}-${v}${type} $(c 0Wdi)(not found - ${code:-000})$(c)"
        logf "  skip ${url} :: http ${code:-000}"        # http code → log file
      fi
    done
  done
  shopt -u nullglob
  "${DRY_RUN}" || log "  fetched ${count} doc jar(s), skipped ${skipped} (no coords) for ${label}"
}

# fetch docs for the war libs and every installed plugin's libs
function fetchAllDocs() {
  log "fetching reference docs (${DOC_TYPES[*]}) for war + plugin libs ..."
  fetchLibDocs "${JENKINS_ROOT}/latest/WEB-INF/lib"
  local name
  for name in "${PLUGINS[@]}"; do
    fetchLibDocs "${PLUGIN_ROOT}/${name}/latest/WEB-INF/lib"
  done
}

# -------------------------------- plugins -----------------------------------
# fetch update-center.actual.json into UC_JSON (once)
function ensureUcJson() {
  if test -z "${UC_JSON}"; then
    UC_JSON="$( command mktemp "${TMPDIR:-/tmp}/uc-actual.XXXXXX.json" )"
    log "fetching update-center metadata ($( ucMeta )) ..."
    command curl -fsSL --max-time 90 -o "${UC_JSON}" "${UC_BASE}/$( ucMeta )/update-center.actual.json" || die 'cannot fetch update-center.actual.json'
  fi
}

# latest plugin version from the cached metadata
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
      "${JENKINS_ROOT}"/* )          ;;          # only our links
      *                   ) continue ;;
    esac
    if test -e "${link}"; then continue; fi      # target exists → keep
    if test 'true' = "${DRY_RUN}"; then
      log "  [DRYRUN] unlink ${link}"
    else
      command unlink "${link}"
      logf "  unlink ${link}"                    # → log file
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
    logf "  link ${GROOVY_LIB}/${base}"          # → log file
    count=$(( count + 1 ))
  done
  shopt -u nullglob
  log "  linked ${count} jar(s) from ${label}"
}

# refresh ~/.groovy/lib: prune dead links, then (re)link war libs + jenkins-core + plugin + extension jars
function relinkLibs() {
  log 'refreshing ~/.groovy/lib symlinks ...'
  act mkdir -p "${GROOVY_LIB}"
  pruneStaleLinks
  linkDir "${JENKINS_ROOT}/latest/WEB-INF/lib"
  linkDir "${JENKINS_ROOT}/latest/core"
  local name
  for name in "${PLUGINS[@]}"; do
    linkDir "${PLUGIN_ROOT}/${name}/latest/WEB-INF/lib"
  done
  local a
  for a in "${EXTENSIONS[@]}"; do
    linkDir "${EXT_ROOT}/${a}/latest"
  done
}

# --clean: remove ~/.groovy/lib links into ${JENKINS_ROOT} + downloaded trees (keeps the script)
function cleanEnv() {
  log "clean: removing managed links + downloaded content under ${JENKINS_ROOT} ..."
  local link count=0
  if test -d "${GROOVY_LIB}"; then
    shopt -s nullglob
    for link in "${GROOVY_LIB}"/*; do
      test -L "${link}" || continue
      case "$( command readlink "${link}" )" in
        "${JENKINS_ROOT}"/* ) act unlink "${link}"; count=$(( count + 1 )) ;;
      esac
    done
    shopt -u nullglob
  fi
  log "  unlinked ${count} jar(s) from ${GROOVY_LIB}"

  local d rc=0
  shopt -s nullglob
  for d in "${JENKINS_ROOT}"/[0-9]* "${JENKINS_ROOT}"/latest "${JENKINS_ROOT}"/plugins "${JENKINS_ROOT}"/extensions "${JENKINS_ROOT}"/logs; do
    { test -e "${d}" || test -L "${d}"; } || continue
    act rm -rf "${d}"
    rc=$(( rc + 1 ))
  done
  shopt -u nullglob
  log "  removed ${rc} item(s) under ${JENKINS_ROOT}"
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
      --lts                           ) WAR_CHANNEL='lts' ;;
      --ln                            ) DO_LINK=true      ;;
      --sources                       ) DO_DOCS=true      ;;
      --javadoc                       ) DO_DOCS=true; DOC_TYPES+=( '-javadoc' ) ;;
      --dryrun | --dry-run            ) DRY_RUN=true      ;;
      --clean                         ) CLEAN=true        ;;
      -p | --path                     ) test -n "${2:-}" || die '--path requires a directory argument'; JENKINS_ROOT="${2}"; shift ;;
      -e | --extension | --extensions ) test -n "${2:-}" || die '--extensions requires an artifact argument'; EXTENSIONS+=( "${2}" ); shift ;;
      -P | --plugin | --plugins       ) test -n "${2:-}" || die '--plugin requires an artifact argument'; PLUGINS+=( "${2}" ); shift ;;
      -h | --help                     ) usage; exit 0     ;;
      *                               ) usage; die "unknown argument: ${1}" ;;
    esac
    shift
  done
}

# derive paths under the (possibly --path-overridden) install root
function resolvePaths() {
  PLUGIN_ROOT="${JENKINS_ROOT}/plugins"
  LOG_ROOT="${JENKINS_ROOT}/logs"
  EXT_ROOT="${JENKINS_ROOT}/extensions"
}

# dedup an array in place (by name), preserving first-seen order (default list + any CLI additions)
function dedupArray() {
  local -n _arr="${1:?array name is required}"
  local -a merged=()
  local -A seen=()
  local x
  for x in "${_arr[@]}"; do
    test -n "${seen[${x}]:-}" && continue
    seen[${x}]=1
    merged+=( "${x}" )
  done
  _arr=( "${merged[@]}" )
}

function main() {
  parseArgs "${@}"
  resolvePaths
  dedupArray PLUGINS
  dedupArray EXTENSIONS
  trap clean EXIT
  if "${CLEAN}"; then cleanEnv; exit 0; fi
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
  installCore
  installExtensions
  local p
  for p in "${PLUGINS[@]}"; do
    installPlugin "${p}"
  done

  if "${DO_DOCS}"; then fetchAllDocs; fi
  if "${DO_LINK}"; then relinkLibs; fi

  ok "done. jenkins=${WAR_VERSION} channel=${WAR_CHANNEL} plugins=${#PLUGINS[@]} extensions=${#EXTENSIONS[@]} docs=${DO_DOCS} link=${DO_LINK} dryrun=${DRY_RUN}"
}

main "${@}"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
