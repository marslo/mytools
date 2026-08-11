#!/usr/bin/env bash
# shellcheck source=/dev/null
# =============================================================================
#      FileName : groovy-libs.sh
#        Author : marslo
#       Created : 2026-05-29 23:20:19
#    LastChange : 2026-08-11 02:10:17
#         Usage : curl -fsSL  https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --groovy --with-libs --with-bin
#                 curl -fsSL  https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --help
# =============================================================================
# download matrix:
#   target                 | binary (.jar)        | -sources / -javadoc | version selection
#   -----------------------+----------------------+---------------------+----------------------------------------
#   --groovy / --with-libs | only with --with-bin | always              | latest stable; --pre adds alpha/beta/rc
#   -e extensions          | always               | always              | latest release; jenkins-core: weekly (X.Y), --extension-lts picks LTS (X.Y.Z)
# note: jenkins-libs.sh also ships -e/--extensions; the duplicated feature is intentional (standalone use)
# =============================================================================

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

readonly MAVEN_BASE="https://repo1.maven.org/maven2"
# base dir; default destination is <base>/libs unless overridden by --path
declare _DEFAULT_DESTINATION='/opt/groovy'
# pinned fallback used only when the online lookup fails
declare _GROOVY_FALLBACK='5.0.8'
declare -a CURL=( 'curl' '-sSLfO' )
declare WITH_LIBS=false
# groovy binaries default off (the launcher already ships them); -sources/-javadoc always download
declare WITH_BIN=false
# --pre: resolve the newest groovy version including alpha/beta/rc (default: stable only)
declare PRE=false
# --extension-lts: for jenkins-style extensions, pick the latest LTS (X.Y.Z) instead of the latest weekly (X.Y)
declare EXT_LTS=false
# -e/--extensions: maven artifacts fetched with bin+sources+javadoc; default list, merged with -e, deduped
declare -a EXTENSIONS=( groovy-cps jenkins-core )
# per-extension overrides; anything not listed defaults to ${MAVEN_BASE} + group 'com/cloudbees'
declare -rA EXTENSION_REPO=(  [jenkins-core]='https://repo.jenkins-ci.org/public' )
declare -rA EXTENSION_GROUP=( [jenkins-core]='org/jenkins-ci/main' )
# extensions following jenkins weekly/lts versioning: default latest weekly (X.Y); --extension-lts picks latest LTS (X.Y.Z)
declare -rA EXTENSION_LTS=( [jenkins-core]=1 )
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
{ test 'bash' = "${ME}" || test -z "${ME}" ; } && ME='groovy-libs.sh'
readonly ME
# shellcheck disable=SC2155
declare -r USAGE="NAME
  $(c 0Ys)${ME}$(c) - Download Groovy core, standard library modules, and jenkins/cloudbees extensions with their sources and javadocs

USAGE
  $(c 0Ys)\$ ${ME}$(c) [OPTIONS]

OPTIONS
  $(c 0G)--groovy $(c Mi)VERSION$(c)            download the Groovy library. Optionally specify the version $(c 0Wi)(default: latest stable, fallback $(c 0Mi)${_GROOVY_FALLBACK}$(c 0Wi))$(c)
  $(c 0G)-l$(c), $(c 0G)--with-libs$(c)             download the Groovy standard library modules
      $(c 0G)--with-bin$(c)              also fetch the compiled groovy '.jar' $(c 0Wi)(default: only -sources/-javadoc, since your launcher already ships the binaries)$(c)
      $(c 0G)--pre$(c)                   resolve the newest groovy version including alpha/beta/rc $(c 0Wi)(default: stable only)$(c)
  $(c 0G)-e$(c), $(c 0G)--extensions $(c 0Mi)ARTIFACT$(c)   download a Jenkins/cloudbees extension jar with bin+sources+javadoc $(c 0Wi)(repeatable; default list [$(c 0Mi)${EXTENSIONS[*]}$(c 0Wi)], deduped)$(c)
      $(c 0G)--extension-lts$(c)         for jenkins-style extensions (jenkins-core), pick the latest LTS $(c 0Mi)X.Y.Z$(c 0Wi) instead of the latest weekly $(c 0Mi)X.Y$(c)
  $(c 0G)-p, $(c 0G)--path $(c 0Mi)DESTINATION$(c)      specify the destination directory $(c 0Wi)(default: ${_DEFAULT_DESTINATION})$(c)
  $(c 0G)-h, $(c 0G)--help$(c)                  show this help message and exit

EXAMPLE
  $(c 0Wdi)# download groovy 6.0.1 jar files and groovy libs, and groovy-cps extension$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--groovy $(c 0Mi)6.0.1 $(c 0Gi)--with-libs --with-bin$(c) $(c 0Gi)--extensions$(c) $(c 0Mi)groovy-cps$(c)

  $(c 0Wdi)# download groovy (latest) to path '/tmp/libs'$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--groovy --path $(c 0Mi)/tmp/libs$(c)

  $(c 0Wdi)# download alpha/beta/rc groovy + groovy libs including the compiled jars$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--groovy --with-libs --with-bin --pre$(c)
"

function show() {
  local layer='38' color='151'
  local -a args=()
  for arg in "$@"; do
    case "${arg}" in
      --fg    ) layer='38'       ;;
      --bg    ) layer='30;48'    ;;
      --info  ) color='151'      ;;
      --warn  ) color='178'      ;;
      --error ) color='174'      ;;
      --note  ) color='117'      ;;
      -*      ) echo -e "Unknown option in show(): '${arg}'" >&2 ;;
      *       ) args+=("${arg}") ;;
    esac
  done
  printf "\033[0;%s;5;%sm%s\033[0m" "${layer}" "${color}" "${args[*]}"
}
function info() { echo -e "$(show --info --bg 'INFO') $(c 0i)$*$(c)"; }

function getVersion() {
  local metadataUrl="${1:?metadata URL is required}"
  command curl -fsSL "${metadataUrl}" 2>/dev/null | sed -n 's/.*<release>\(.*\)<\/release>.*/\1/p'
}

# latest groovy from maven central; skips alpha/beta/rc unless --pre is set
# BSD/GNU-portable: extract all <version> entries (ascending), optionally drop pre-releases, take the last
function latestGroovy() {
  local xml
  xml="$( command curl -fsSL "${MAVEN_BASE}/org/apache/groovy/groovy/maven-metadata.xml" 2>/dev/null )"
  local versions
  versions="$( printf '%s' "${xml}" | sed -nE 's/.*<version>(.*)<\/version>.*/\1/p' )"
  "${PRE}" || versions="$( printf '%s\n' "${versions}" | command grep -viE 'alpha|beta|rc' )"
  printf '%s\n' "${versions}" | tail -1
}

# resolve the default version on demand; fall back to the pinned constant on failure
function defaultVersion() {
  local kind="${1:?kind is required}"
  local version=''
  case "${kind}" in
    groovy ) version="$(latestGroovy)" ; echo "${version:-${_GROOVY_FALLBACK}}" ;;
  esac
}

# (re)point <baseDir>/latest at the downloaded <version> subdir (relative symlink)
function linkLatest() {
  local baseDir="${1:?base dir is required}"
  local version="${2:?version is required}"
  ln -sfn "${version}" "${baseDir}/latest"
  info "linked $(c 0G)${baseDir}/latest $(c 0i)-> $(c 0G)${version}$(c)"
}

# build the list of jar suffixes to fetch: always -sources/-javadoc; binary '' only when withJar is true
# usage: readFetchTypes <true|false> <arrayName>
function fetchTypes() {
  local withJar="${1:?withJar is required}"
  local -n _types="${2:?types array name is required}"
  _types=( '-sources' '-javadoc' )
  "${withJar}" && _types=( '' "${_types[@]}" )
}

# download groovy library modules from maven central into ${2:-destDir}; if no version ($4) is specified, it will try to get the latest version from maven-metadata.xml
#   ${MAVEN_BASE}/${3:-group}/${1:-artifact}/${4:-version}{,-sources,-javadoc}.jar
function extensions() {
  # nameref
  local -n artifacts="${1:?artifact is required}"
  local destDir="${2:?destination dir is required}"
  local group="${3:-com/cloudbees}"
  local version="${4:-}"
  local withJar="${5:-true}"
  local -a types=()
  fetchTypes "${withJar}" types
  mkdir -p "${destDir}"
  cd "${destDir}" || exit

  for artifact in "${artifacts[@]}"; do
    local url="${MAVEN_BASE}/${group}/${artifact}"
    test -n "${version}" || version="$(getVersion "${url}/maven-metadata.xml")"
    test -n "${version}" || { echo -e "$(show --bg --error 'ERROR') $(c 0i)failed to get the latest version of $(c 0G)${artifact} $(c 0i)from $(c 0Bui)${url}$(c 0i) ..."; exit 1; }

    info "downloading libs $(c 0G)${artifact} v${version} $(c 0i)from $(c 0Bui)${url}$(c 0i) ..."
    for type in "${types[@]}"; do
      "${CURL[@]}" "${url}/${version}/${artifact}-${version}${type}.jar"
    done
  done
}

function groovy() {
  local version="${1:-${_GROOVY_FALLBACK}}"
  local group='org/apache/groovy'
  local artifact='groovy'
  local target="${GROOVY_DIR}/${version}"
  local repo="${MAVEN_BASE}/${group}/${artifact}/${version}"
  local -a types=()
  fetchTypes "${WITH_BIN}" types

  info "downloading $(c 0G)${artifact} v${version} $(c 0i)from $(c 0Bui)${repo}$(c 0i) ..."
  mkdir -p "${target}"
  cd "${target}" || exit
  for type in "${types[@]}"; do
    "${CURL[@]}" "${repo}/groovy-${version}${type}.jar"
  done
  linkLatest "${GROOVY_DIR}" "${version}"
}

function groovylibs() {
  local version="${1:-$(defaultVersion groovy)}"
  local group='org/apache/groovy'
  local target="${GROOVY_DIR}/${version}"
  local -a _modules=()
  while read -r module _version; do
    _modules+=("${module}")
  done< <( /bin/ls --color=never -1 "${GROOVYH_HOME:-/opt/homebrew/opt/groovy/libexec}"/lib/groovy-*.jar | sed -nE 's:^.*/([^/]+.)-([0-9.]+)\.jar:\1 \2:p' )
  [[ ${#_modules[@]} -gt 0 ]] && { extensions _modules "${target}" "${group}" "${version}" "${WITH_BIN}"; linkLatest "${GROOVY_DIR}" "${version}"; }
}

# download one maven extension (bin+sources+javadoc) into <EXTENSIONS_DIR>/<artifact>/<version>,
# then (re)point <artifact>/latest at it. version resolved from maven-metadata.xml.
# repo/group default to maven central + com/cloudbees; override per artifact via EXTENSION_REPO/EXTENSION_GROUP.
function installExtension() {
  local artifact="${1:?artifact is required}"
  local repo="${EXTENSION_REPO[${artifact}]:-${MAVEN_BASE}}"
  local group="${EXTENSION_GROUP[${artifact}]:-com/cloudbees}"
  local base="${EXTENSIONS_DIR}/${artifact}"
  local url="${repo}/${group}/${artifact}"
  local version
  if test -n "${EXTENSION_LTS[${artifact}]:-}"; then
    # jenkins-style weekly/lts: default latest weekly (X.Y); --extension-lts picks latest LTS (X.Y.Z)
    local pat='^[0-9]+\.[0-9]+$'
    "${EXT_LTS}" && pat='^[0-9]+\.[0-9]+\.[0-9]+$'
    version="$( command curl -fsSL "${url}/maven-metadata.xml" 2>/dev/null | sed -nE 's:.*<version>(.*)</version>.*:\1:p' | command grep -E "${pat}" | tail -1 )"
  else
    version="$(getVersion "${url}/maven-metadata.xml")"
  fi
  test -n "${version}" || { echo -e "$(show --bg --error 'ERROR') $(c 0i)failed to get the latest version of $(c 0G)${artifact} $(c 0i)from $(c 0Bui)${url}$(c 0i) ..."; exit 1; }
  local target="${base}/${version}"
  local -a types=()
  fetchTypes true types                          # extensions always include the binary jar
  info "downloading extensions $(c 0G)${artifact} v${version} $(c 0i)from $(c 0Bui)${url}$(c 0i) ..."
  mkdir -p "${target}"
  cd "${target}" || exit
  for type in "${types[@]}"; do
    "${CURL[@]}" "${url}/${version}/${artifact}-${version}${type}.jar"
  done
  linkLatest "${base}" "${version}"
}

function _parser() {
  local flag="$1"
  # nameref
  local -n _ver="$2"
  local argc="$3"
  local next="${4-}"

  # --groovy -> without version, resolve the latest on demand
  if [[ ${argc} -le 1 || "${next}" == -* ]]; then
    _ver="$( defaultVersion "${flag}" )"
    return 1
  # --groovy 5.0.6 -> with version
  elif [[ "${next}" =~ ^[0-9]+(\.[0-9]+)+([._-][a-zA-Z0-9]+)*$ ]]; then
    _ver="${next}"
    return 2
  else
    echo "ERROR: invalid version '${next}' for --${flag}" >&2
    exit 1
  fi
}

# print environment-setup hints for whatever was actually downloaded this run
function printNotes() {
  local -a refLibs=() cliDirs=()
  # groovy/latest + extensions feed both the LSP (referencedLibraries) and the groovy/java classpath
  { test -n "${GROOVY_VERSION:-}" || "${WITH_LIBS}"; } && { refLibs+=( "${GROOVY_DIR}/latest/*" ); cliDirs+=( "${GROOVY_DIR}/latest" ); }
  local ext
  for ext in "${EXTENSIONS[@]}"; do refLibs+=( "${EXTENSIONS_DIR}/${ext}/latest/*" ); cliDirs+=( "${EXTENSIONS_DIR}/${ext}/latest" ); done
  [[ ${#refLibs[@]} -eq 0 ]] && return 0

  local refJoined cpJoined
  refJoined="$( printf '"%s", ' "${refLibs[@]}" )"; refJoined="${refJoined%, }"
  # java classpath wildcard: <dir>/* expands to every .jar in <dir> (incl. -sources/-javadoc, useful for the LSP)
  cpJoined="$( printf '%s/*:' "${cliDirs[@]}" )"; cpJoined="${cpJoined%:}"

  echo -e "$(show --bg --note ' NOTE ') $(c 0i)environment setup for the libraries above:$(c)"
  echo -e "  • nvim coc-groovy $(c 0Bui)~/.config/nvim/coc-settings.json $(c 0i)(LSP resolves against these jars):$(c)"
  echo -e "      $(c 0G)\"groovy.project.referencedLibraries\": [ ${refJoined} ]$(c)"
  echo -e "  • groovy CLI $(c 0Bui)~/.bashrc $(c 0i)(add the downloaded jars to the groovy/java classpath):$(c)"
  echo -e "      $(c 0G)export GROOVY_CLASSPATH=\"\${GROOVY_CLASSPATH:+\$GROOVY_CLASSPATH:}${cpJoined}\"$(c)"
  echo -e "      $(c 0G)export CLASSPATH=\"\${CLASSPATH:+\$CLASSPATH:}${cpJoined}\"$(c)"
}

# dedup EXTENSIONS in place, preserving first-seen order (default list + any -e artifacts)
function dedupExtensions() {
  local -a merged=()
  local -A seen=()
  local x
  for x in "${EXTENSIONS[@]}"; do
    test -n "${seen[${x}]:-}" && continue
    seen[${x}]=1
    merged+=( "${x}" )
  done
  EXTENSIONS=( "${merged[@]}" )
}

function main() {
  dedupExtensions
  test -n "${GROOVY_VERSION:-}" && groovy "${GROOVY_VERSION}"
  "${WITH_LIBS}"                && groovylibs "${GROOVY_VERSION}"
  local ext
  for ext in "${EXTENSIONS[@]}"; do installExtension "${ext}"; done

  echo -e "$(show --bg --note ' ✓ ') The libraries are ready!"
  printNotes
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --groovy          ) _parser groovy GROOVY_VERSION $# "${2-}" ; shift $? ;;
    -l | --with-libs  ) WITH_LIBS=true      ; shift   ;;
    --with-bin        ) WITH_BIN=true       ; shift   ;;
    --pre             ) PRE=true            ; shift   ;;
    --extension-lts   ) EXT_LTS=true        ; shift   ;;
    -e | --extensions ) EXTENSIONS+=("$2")  ; shift 2 ;;
    -p | --path       ) DESTINATION="$2"    ; shift 2 ;;
    -h | --help       ) echo -e "${USAGE}" >&2; exit 0 ;;
    *                 ) echo "ERROR: unknown option '$1'"; exit 1;;
  esac
done

DESTINATION="${DESTINATION:-${_DEFAULT_DESTINATION}}"
# base dir; each download lands in <base>/<version> with a <base>/latest symlink
declare GROOVY_DIR="${DESTINATION}"
declare EXTENSIONS_DIR="${DESTINATION}/extensions"

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
