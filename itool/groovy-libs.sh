#!/usr/bin/env bash
# shellcheck source=/dev/null
# =============================================================================
#      FileName : groovy-libs.sh
#        Author : marslo
#       Created : 2026-05-29 23:20:19
#    LastChange : 2026-08-07 23:38:23
# =============================================================================
# download matrix:
#   target                   | binary (.jar) | -sources / -javadoc | affected by --with-jar
#   -------------------------+---------------+---------------------+-----------------------
#   --groovy / --groovy-libs | skip default  | always              | yes: --with-jar adds binary
#   --jenkins                | always        | always              | no (CLI needs it; nowhere else)
#   -e extensions            | always        | always              | no
# =============================================================================

# @credit: https://github.com/ppo/bash-colors
# @usage:  or copy & paste the `c()` function from:
#          https://github.com/ppo/bash-colors/blob/master/bash-colors.sh#L3
source "${HOME}/.marslo/bin/bash-colors.sh" 2>/dev/null || { c() { :; }; }

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

# latest stable groovy from maven central (skip alpha/beta/rc)
function latestGroovy() {
  command curl -fsSL "${MAVEN_BASE}/org/apache/groovy/groovy/maven-metadata.xml" 2>/dev/null | sed -nE '/<version>/{/alpha|beta|rc/!s/.*<version>(.*)<\/version>.*/\1/p}' | tail -1
}

# latest jenkins LTS core version
function latestJenkins() {
  command curl -fsSL 'https://updates.jenkins.io/stable/latestCore.txt' 2>/dev/null | tr -d '[:space:]'
}

# resolve the default version on demand; fall back to the pinned constant on failure
function defaultVersion() {
  local kind="${1:?kind is required}"
  local version=''
  case "${kind}" in
    groovy  ) version="$(latestGroovy)" ;  echo "${version:-${_GROOVY_FALLBACK}}"  ;;
    jenkins ) version="$(latestJenkins)" ; echo "${version:-${_JENKINS_FALLBACK}}" ;;
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

# to download extensions/libs from maven central into ${2:-destDir}
# if no version ($4) is specified, it will try to get the latest version from maven-metadata.xml
# ${5:-withJar} controls whether the compiled '.jar' is fetched alongside -sources/-javadoc (default: true)
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

    info "downloading extensions/libs $(c 0G)${artifact} v${version} $(c 0i)from $(c 0Bui)${url}$(c 0i) ..."
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
  fetchTypes "${WITH_JAR}" types

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
  [[ ${#_modules[@]} -gt 0 ]] && { extensions _modules "${target}" "${group}" "${version}" "${WITH_JAR}"; linkLatest "${GROOVY_DIR}" "${version}"; }
}

function jenkins() {
  local version="${1:-${_JENKINS_FALLBACK}}"
  local group='org/jenkins-ci/main'
  local artifact='jenkins-core'
  local target="${JENKINS_DIR}/${version}"
  local repo="https://repo.jenkins-ci.org/public/${group}/${artifact}/${version}"

  info "downloading $(c 0G)${artifact} v${version} $(c 0i)from $(c 0Bui)${repo}$(c 0i) ..."
  mkdir -p "${target}"
  cd "${target}" || exit
  for type in "" "-sources" "-javadoc"; do
    "${CURL[@]}" "${repo}/jenkins-core-${version}${type}.jar"
  done
  linkLatest "${JENKINS_DIR}" "${version}"
}

function _parser() {
  local flag="$1"
  # nameref
  local -n _ver="$2"
  local argc="$3"
  local next="${4-}"

  # --java --jenkins -> without version, resolve the latest on demand
  if [[ ${argc} -le 1 || "${next}" == -* ]]; then
    _ver="$( defaultVersion "${flag}" )"
    return 1
  # --java 5.0.6 -> with version
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
  # groovy/latest feeds the LSP only (sources/javadoc + symbol resolution); the CLI gets groovy from its launcher
  { test -n "${GROOVY_VERSION:-}" || "${GROOVYLIBS}"; } && refLibs+=( "${GROOVY_DIR}/latest/*" )
  test -n "${JENKINS_VERSION:-}" && { refLibs+=( "${JENKINS_DIR}/latest/*" ); cliDirs+=( "${JENKINS_DIR}/latest" ); }
  [[ ${#EXTENSIONS[@]} -gt 0 ]]  && { refLibs+=( "${EXTENSIONS_DIR}/*" );      cliDirs+=( "${EXTENSIONS_DIR}" ); }
  [[ ${#refLibs[@]} -eq 0 ]] && return 0

  local refJoined
  refJoined="$( printf '"%s", ' "${refLibs[@]}" )"; refJoined="${refJoined%, }"

  echo -e "$(show --bg --note ' NOTE ') $(c 0i)environment setup for the libraries above:$(c)"
  echo -e "  $(c 0i)• nvim coc-groovy $(c 0Bui)~/.config/nvim/coc-settings.json$(c)$(c 0i) (LSP resolves against these jars):$(c)"
  echo -e "      $(c 0G)\"groovy.project.referencedLibraries\": [ ${refJoined} ]$(c)"
  echo -e "  $(c 0i)• groovy CLI $(c 0Bui)~/.bashrc$(c)$(c 0i) (groovy comes from your launcher; add only what it lacks):$(c)"
  if [[ ${#cliDirs[@]} -gt 0 ]]; then
    echo -e "      $(c 0G)export CLASSPATH=\"\${CLASSPATH:+\$CLASSPATH:}\$( find ${cliDirs[*]} -name '*.jar' ! -name '*-sources.jar' ! -name '*-javadoc.jar' | paste -sd: - )\"$(c)"
  else
    echo -e "      $(c 0i)nothing to add — groovy is provided by your launcher (\$GROOVY_HOME/lib).$(c)"
  fi
}

function main() {
  test -n "${GROOVY_VERSION:-}"  && groovy "${GROOVY_VERSION}"
  test -n "${JENKINS_VERSION:-}" && jenkins "${JENKINS_VERSION}"
  "${GROOVYLIBS}"                && groovylibs "${GROOVY_VERSION}"
  [[ ${#EXTENSIONS[@]} -gt 0 ]]  && extensions EXTENSIONS "${EXTENSIONS_DIR}"

  echo -e "$(show --bg --note ' ✓ ') The libraries are ready!"
  printNotes
}

readonly MAVEN_BASE="https://repo1.maven.org/maven2"
declare _DEFAULT_DESTINATION='/opt/groovy/libs'
# pinned fallbacks used only when the online lookup fails
declare _GROOVY_FALLBACK='5.0.8'
declare _JENKINS_FALLBACK='2.568.2'
declare -a CURL=( 'curl' '-sSLfO' )
declare GROOVYLIBS=false
# groovy binaries default off (the launcher already ships them); -sources/-javadoc always download
declare WITH_JAR=false
declare -a EXTENSIONS=()
declare -r USAGE="NAME
  $0 - Download Groovy and Jenkins Core libraries and their sources and javadocs

USAGE
  \$ $0 [OPTIONS]

OPTIONS
  --groovy \033[0;2;3;37mVERSION\033[0m            download the Groovy library. Optionally specify the version (default: latest stable, fallback ${_GROOVY_FALLBACK})
  --jenkins \033[0;2;3;37mVERSION\033[0m           download the Jenkins Core library. Optionally specify the version (default: latest LTS, fallback ${_JENKINS_FALLBACK})
  -l, --groovy-libs            download the Groovy libraries
  -e, --extensions \033[0;2;3;37mARTIFACT\033[0m   download the specified Jenkins/cloudbees extension library (e.g., groovy-cps)
      --with-jar              also fetch the compiled groovy '.jar' (default: only -sources/-javadoc, since your launcher already ships the binaries)
  -p, --path \033[0;2;3;37mDESTINATION\033[0m      specify the destination directory (default: ${_DEFAULT_DESTINATION})
  -h, --help                  show this help message and exit

EXAMPLE
  \033[0;2;3;37m# download groovy 6.0.1, jenkins 2.566 jar files and groovy libs\033[0m
  \$ $0 --groovy 6.0.1 --jenkins 2.566 --groovy-libs

  \033[0;2;3;37m# download groovy and jenkins jar files with the latest version to path '/tmp/libs'\033[0m
  \$ $0 --groovy --jenkins --path /tmp/libs

  \033[0;2;3;37m# download groovy and jenkins jar files with the latest version to path '/tmp/libs'\033[0m
  \$ $0 --groovy --jenkins --groovy-libs --with-jar
"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --groovy          ) _parser groovy  GROOVY_VERSION  $# "${2-}" ; shift $? ;;
    --jenkins         ) _parser jenkins JENKINS_VERSION $# "${2-}" ; shift $? ;;
    -l | --groovy-libs ) GROOVYLIBS=true    ; shift   ;;
    --with-jar        ) WITH_JAR=true      ; shift   ;;
    -e | --extensions ) EXTENSIONS+=("$2") ; shift 2 ;;
    -p | --path       ) DESTINATION="$2"   ; shift 2 ;;
    -h | --help       ) echo -e "${USAGE}" >&2; exit 0 ;;
    *                 ) echo "ERROR: unknown option '$1'"; exit 1;;
  esac
done

DESTINATION="${DESTINATION:-${_DEFAULT_DESTINATION}}"
# base dirs; each download lands in <base>/<version> with a <base>/latest symlink
declare GROOVY_DIR="${DESTINATION}/groovy"
declare JENKINS_DIR="${DESTINATION}/jenkins"
declare EXTENSIONS_DIR="${DESTINATION}/extensions"

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
