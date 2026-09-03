#!/usr/bin/env bash
# shellcheck source=/dev/null
# =============================================================================
#      FileName : groovy-libs.sh
#        Author : marslo
#       Created : 2026-05-29 23:20:19
#    LastChange : 2026-09-02 02:47:43
#         Usage : curl -fsSL  https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --jar --with-libs --with-bin
#                 curl -fsSL  https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --runtime --latest
#                 curl -fsSL  https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --help
# =============================================================================
# download matrix:
#   target              | binary (.jar)        | -sources / -javadoc | version selection
#   --------------------+----------------------+---------------------+-----------------------------------------
#   --jar / --with-libs | only with --with-bin | always              | system version; --latest stable; --pre alpha/beta/rc
#   --runtime           | full binary zip      | (bundled in zip)    | latest stable (default); --pre alpha/beta/rc
#   -e extensions       | always               | always              | latest release; jenkins-core: weekly (X.Y), --extension-lts LTS (X.Y.Z)
# =============================================================================

# require bash >= 4.3 (associative arrays + namerefs used throughout)
if test "${BASH_VERSINFO[0]:-0}" -lt 4 || { test "${BASH_VERSINFO[0]}" -eq 4 && test "${BASH_VERSINFO[1]:-0}" -lt 3; }; then
  echo "error: bash >= 4.3 required (found ${BASH_VERSION:-unknown}); on macOS install & run via homebrew bash (brew install bash)" >&2
  exit 1
fi

# @credit: https://github.com/ppo/bash-colors
# shellcheck disable=SC2015,SC2059
c() { [ $# == 0 ] && printf "\033[0m" || printf "$1" | sed 's/\(.\)/\1;/g;s/\([SDIUFNHT]\)/2\1/g;s/\([KRGYBMCW]\)/3\1/g;s/\([krgybmcw]\)/4\1/g;y/SDIUFNHTsdiufnhtKRGYBMCWkrgybmcw/12345789123457890123456701234567/;s/^\(.*\);$/\\033[\1m/g'; }

readonly MAVEN_BASE="https://repo1.maven.org/maven2"
# --runtime: full binary distribution zip (apache-groovy-binary-<ver>.zip)
readonly RUNTIME_BASE="https://groovy.jfrog.io/artifactory/dist-release-local/groovy-zips"
# default install root (-p overrides)
declare _DEFAULT_DESTINATION='/opt/groovy'
# fallback version if lookup fails
declare _GROOVY_FALLBACK='5.0.8'
# system groovy home; auto-detected in main()
declare _GROOVY_SYS_HOME="${GROOVY_HOME:-}"
declare WITH_LIBS=false
# groovy binaries off by default; -sources/-javadoc always
declare WITH_BIN=false
# --runtime: download the full binary distribution and link <dest>/current at it
declare RUNTIME=false
# --pre: newest incl. alpha/beta/rc
declare PRE=false
# --latest: maven latest stable
declare LATEST=false
# --extension-lts: pick latest LTS (X.Y.Z) not weekly (X.Y)
declare EXT_LTS=false
# --clean: remove downloaded libs + extensions + latest, then exit
declare CLEAN=false
# extensions (bin+sources+javadoc); merged with -e, deduped
declare -a EXTENSIONS=( groovy-cps jenkins-core )
# per-extension repo / group overrides
declare -rA EXTENSION_REPO=(  [jenkins-core]='https://repo.jenkins-ci.org/public' )
declare -rA EXTENSION_GROUP=( [jenkins-core]='org/jenkins-ci/main' )
# extensions using jenkins weekly/lts versioning
declare -rA EXTENSION_LTS=( [jenkins-core]=1 )
# maven group per artifact for jars without pom.properties (prefix families in resolveGroup)
declare -rA LIB_GROUP=(
  [junit]='junit'                      [testng]='org.testng'
  [gpars]='org.codehaus.gpars'         [hamcrest-core]='org.hamcrest'
  [ivy]='org.apache.ivy'               [jcommander]='org.jcommander'
  [jna]='net.java.dev.jna'             [jsr166y]='org.codehaus.jsr166-mirror'
  [opentest4j]='org.opentest4j'        [javaparser-core]='com.github.javaparser'
  [jquery]='org.webjars'               [multiverse-core]='org.multiverse'
  [mxparser]='io.github.x-stream'      [qdox]='com.thoughtworks.qdox'
  [slf4j-api]='org.slf4j'              [snakeyaml]='org.yaml'
  [xstream]='com.thoughtworks.xstream' [commons-cli]='commons-cli'
  [org.abego.treelayout.core]='org.abego.treelayout'
)
# groovy modules for the no-system fallback (from org.apache.groovy)
declare -ra GROOVY_MODULES=(
  groovy groovy-ant groovy-astbuilder groovy-cli-commons groovy-cli-picocli groovy-console
  groovy-contracts groovy-datetime groovy-dateutil groovy-docgenerator groovy-ginq
  groovy-groovydoc groovy-groovysh groovy-jmx groovy-json groovy-jsr223 groovy-macro
  groovy-macro-library groovy-nio groovy-servlet groovy-sql groovy-swing groovy-templates
  groovy-test groovy-test-junit5 groovy-testng groovy-toml groovy-typecheckers groovy-xml groovy-yaml
)
declare ME; ME="$( basename "${BASH_SOURCE[0]:-$0}" )"
{ test 'bash' = "${ME}" || test -z "${ME}" ; } && ME='groovy-libs.sh'
readonly ME
# shellcheck disable=SC2155
declare -r USAGE="NAME
  $(c 0Ys)${ME}$(c) - Download Groovy core, standard library modules, and jenkins/cloudbees extensions with their sources and javadocs

USAGE
  $(c 0Ys)\$ ${ME}$(c) [OPTIONS]

OPTIONS
  $(c 0G)--latest$(c)                    for $(c 0Mi)--jar$(c): use the latest stable groovy from maven central $(c 0Wi)(default: system groovy version; $(c 0Mi)--runtime$(c 0Wi) already installs latest)$(c)
  $(c 0G)--pre$(c)                       for $(c 0Mi)--jar$(c)/$(c 0Mi)--runtime$(c): use the newest groovy including alpha/beta/rc $(c 0Wi)(default: stable only)$(c)
  $(c 0G)-p, $(c 0G)--path $(c 0Mi)DESTINATION$(c)      specify the destination directory $(c 0Wi)(default: ${_DEFAULT_DESTINATION})$(c)

  $(c 0G)--runtime$(c)                   download the full binary distribution ($(c 0Mi)apache-groovy-binary-<ver>.zip$(c)) and link $(c 0Wi)<dest>/current$(c) -> it $(c 0Wi)(latest stable)$(c)
  $(c 0G)--jar $(c Mi)VERSION$(c)               download the Groovy core jar(s). Optionally specify the version $(c 0Wi)(default: system groovy; fallback $(c 0Mi)${_GROOVY_FALLBACK}$(c 0Wi); alias: $(c 0Mi)--groovy$(c 0Wi))$(c)
  $(c 0G)-l$(c), $(c 0G)--with-libs$(c)             fetch -sources/-javadoc for every jar in the system groovy lib $(c 0Wi)(requires $(c 0Mi)--jar$(c 0Wi); auto-detects brew/sdkman/apt/\$GROOVY_HOME)$(c)
      $(c 0G)--with-bin$(c)              also fetch the compiled groovy '.jar' $(c 0Wi)(requires $(c 0Mi)--jar$(c 0Wi))$(c)

  $(c 0G)-e$(c), $(c 0G)--extensions $(c 0Mi)ARTIFACT$(c)   download a Jenkins/cloudbees extension jar with bin+sources+javadoc $(c 0Wi)(repeatable; default list [$(c 0Mi)${EXTENSIONS[*]}$(c 0Wi)], deduped)$(c)
      $(c 0G)--extension-lts$(c)         for jenkins-style extensions (jenkins-core), pick the latest LTS $(c 0Mi)X.Y.Z$(c 0Wi) instead of the latest weekly $(c 0Mi)X.Y$(c)

  $(c 0G)--clean$(c)                     remove downloaded version dirs + $(c 0Wi)latest$(c) + $(c 0Wi)extensions$(c) under the destination, then exit $(c 0Wi)(keeps the script)$(c)
  $(c 0G)-h, $(c 0G)--help$(c)                  show this help message and exit

EXAMPLE
  $(c 0Wdi)# download groovy 6.0.1 jar files and groovy libs, and groovy-cps extension$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--jar $(c 0Mi)6.0.1 $(c 0Gi)--with-libs --with-bin$(c) $(c 0Gi)--extensions$(c) $(c 0Mi)groovy-cps$(c)

  $(c 0Wdi)# download groovy (latest stable) jars to path '/tmp/libs'$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--jar --latest --path $(c 0Mi)/tmp/libs$(c)

  $(c 0Wdi)# download alpha/beta/rc groovy + groovy libs including the compiled jars$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--jar --with-libs --with-bin --pre$(c)

  $(c 0Wdi)# install the full groovy binary distribution (latest stable) and link <dest>/current -> it$(c)
  $(c 0Y)\$ ${ME} $(c 0Gi)--runtime --latest$(c)
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

# download one jar into <outdir>; on 404/failure print "skip: <name> (not found - <code>)"
function fetchJar() {
  local url="${1}" outdir="${2}" name code
  name="${url##*/}"
  if code="$( command curl -sfL -o "${outdir}/${name}" -w '%{http_code}' "${url}" 2>/dev/null )"; then return 0; fi
  command rm -f "${outdir}/${name}"
  info "  $(c 0Y)skip$(c 0i): ${name%.jar} $(c 0Wdi)(not found - ${code:-000})$(c)"
  return 1
}

function getVersion() {
  local metadataUrl="${1:?metadata URL is required}"
  command curl -fsSL "${metadataUrl}" 2>/dev/null | sed -n 's/.*<release>\(.*\)<\/release>.*/\1/p'
}

# latest groovy from maven central (skips alpha/beta/rc unless --pre)
function latestGroovy() {
  local xml
  xml="$( command curl -fsSL "${MAVEN_BASE}/org/apache/groovy/groovy/maven-metadata.xml" 2>/dev/null )"
  local versions
  versions="$( printf '%s' "${xml}" | sed -nE 's/.*<version>(.*)<\/version>.*/\1/p' )"
  "${PRE}" || versions="$( printf '%s\n' "${versions}" | command grep -viE 'alpha|beta|rc' )"
  printf '%s\n' "${versions}" | tail -1
}

# system groovy home: $GROOVY_HOME, brew, sdkman, apt, or the groovy launcher on PATH
function detectGroovyHome() {
  local -a candidates=(
    "${GROOVY_HOME:-}"
    '/opt/homebrew/opt/groovy/libexec'
    '/usr/local/opt/groovy/libexec'
    "${HOME}/.sdkman/candidates/groovy/current"
    '/usr/share/groovy'
    '/opt/groovy/current'
  )
  local bin; bin="$( command -v groovy 2>/dev/null )"
  if test -n "${bin}"; then
    local real; real="$( readlink -f "${bin}" 2>/dev/null || printf '%s' "${bin}" )"
    candidates+=( "$( dirname "$( dirname "${real}" )" )" )
  fi
  local d
  for d in "${candidates[@]}"; do
    test -n "${d}" || continue
    compgen -G "${d}/lib/groovy-[0-9]*.jar" >/dev/null 2>&1 && { printf '%s' "${d}"; return 0; }
  done
  return 1
}

# version of the system groovy (<sys-home>/lib/groovy-*.jar)
function systemGroovyVersion() {
  local ver
  ver="$( command ls -1 "${_GROOVY_SYS_HOME}"/lib/groovy-[0-9]*.jar 2>/dev/null | head -1 \
          | sed -nE 's:.*/groovy-([0-9][0-9.]*)\.jar:\1:p' )"
  test -n "${ver}" || ver="$( command groovy --version 2>/dev/null | sed -nE 's/.*Groovy Version:[[:space:]]*([0-9][0-9._-]*).*/\1/p' | head -1 )"
  printf '%s' "${ver}"
}

# default version: system groovy; --latest/--pre → maven newest; fallback constant
function defaultVersion() {
  local kind="${1:?kind is required}"
  local version=''
  case "${kind}" in
    # maven newest || system groovy
    groovy ) if "${LATEST}" || "${PRE}"; then version="$(latestGroovy)"; else version="$(systemGroovyVersion)"; fi
             echo "${version:-${_GROOVY_FALLBACK}}" ;;
  esac
}

# point <baseDir>/latest at <version>
function linkLatest() {
  local baseDir="${1:?base dir is required}"
  local version="${2:?version is required}"
  ln -sfn "${version}" "${baseDir}/latest"
  info "linked $(c 0G)${baseDir}/latest $(c 0i)-> $(c 0G)${version}$(c)"
}

# jar suffixes to fetch: -sources/-javadoc, plus '' when withJar
# usage: fetchTypes <true|false> <arrayName>
function fetchTypes() {
  local withJar="${1:?withJar is required}"
  local -n _types="${2:?types array name is required}"
  _types=( '-sources' '-javadoc' )
  "${withJar}" && _types=( '' "${_types[@]}" )
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
  for type in "${types[@]}"; do
    fetchJar "${repo}/groovy-${version}${type}.jar" "${target}"
  done
  linkLatest "${GROOVY_DIR}" "${version}"
}

# --runtime: download the full binary distribution (apache-groovy-binary-<ver>.zip),
# extract under <GROOVY_DIR>, and point <GROOVY_DIR>/current at groovy-<ver>
function installRuntime() {
  # --runtime installs precisely because there is no system groovy, so never
  # resolve against the system: default to the latest stable (or the newest
  # incl. alpha/beta/rc with --pre). an explicit --jar VERSION pin still wins.
  local version="${1-}"
  { test -z "${version}" || test '@default' = "${version}"; } && version="$( latestGroovy )"
  version="${version:-${_GROOVY_FALLBACK}}"
  command -v unzip >/dev/null 2>&1 || {
    echo -e "$(show --bg --error 'ERROR') $(c 0i)$(c 0G)unzip$(c 0i) is required for $(c 0G)--runtime$(c 0i) but not found$(c)" >&2
    exit 1
  }

  local dist="apache-groovy-binary-${version}.zip"
  local extracted="${GROOVY_DIR}/groovy-${version}"

  # reuse a previous extraction; otherwise download + verify + unzip
  if test -d "${extracted}" && compgen -G "${extracted}/lib/groovy-[0-9]*.jar" >/dev/null 2>&1; then
    info "reuse existing groovy runtime $(c 0G)${extracted}$(c)"
  else
    local zip="${GROOVY_DIR}/${dist}"
    # jfrog primary; maven central (byte-identical) fallback
    local -a sources=(
      "${RUNTIME_BASE}/${dist}"
      "${MAVEN_BASE}/org/apache/groovy/groovy-binary/${version}/groovy-binary-${version}.zip"
    )
    mkdir -p "${GROOVY_DIR}"
    local url ok=false
    for url in "${sources[@]}"; do
      info "downloading $(c 0G)groovy runtime v${version} $(c 0i)from $(c 0Bui)${url}$(c 0i) ..."
      command curl -fsSL --retry 3 --retry-delay 2 -o "${zip}" "${url}" || continue
      unzip -tqq "${zip}" >/dev/null 2>&1 && { ok=true; break; }        # reject a truncated/corrupt archive
      info "  $(c 0Y)skip$(c 0i): incomplete archive from this source"
    done
    "${ok}" || {
      command rm -f "${zip}"
      echo -e "$(show --bg --error 'ERROR') $(c 0i)failed to download a valid $(c 0G)${dist}$(c)" >&2
      exit 1
    }
    # true top-level dir from the archive (groovy-<ver> by convention)
    local top; top="$( unzip -Z1 "${zip}" | sed -nE 's:^([^/]+)/.*:\1:p' | head -1 )"
    extracted="${GROOVY_DIR}/${top}"
    command rm -rf "${extracted}"
    info "extracting $(c 0G)${dist} $(c 0i)-> $(c 0G)${extracted}$(c) ..."
    unzip -q "${zip}" -d "${GROOVY_DIR}"
    command rm -f "${zip}"
  fi

  local name; name="$( basename "${extracted}" )"
  ln -sfn "${name}" "${GROOVY_DIR}/current"
  info "linked $(c 0G)${GROOVY_DIR}/current $(c 0i)-> $(c 0G)${name}$(c)"
}

# maven group for an artifact: prefix families, then LIB_GROUP (empty if unknown)
function resolveGroup() {
  case "${1}" in
    groovy | groovy-*    ) printf 'org.apache.groovy'                ;;
    ant | ant-*          ) printf 'org.apache.ant'                   ;;
    jline-* | jansi      ) printf 'org.jline'                        ;;
    jackson-dataformat-* ) printf 'com.fasterxml.jackson.dataformat' ;;
    jackson-*            ) printf 'com.fasterxml.jackson.core'       ;;
    junit-jupiter-*      ) printf 'org.junit.jupiter'                ;;
    junit-platform-*     ) printf 'org.junit.platform'               ;;
    *                    ) printf '%s' "${LIB_GROUP[${1}]:-}"        ;;
  esac
}

# fetch -sources/-javadoc (+bin with --with-bin) for every system-lib jar;
# no system install → standard groovy modules at ${version}
function groovylibs() {
  local version="${1:-$(defaultVersion groovy)}"
  local libDir="${_GROOVY_SYS_HOME}/lib"
  local target="${GROOVY_DIR}/${version}"
  local -a types=()
  fetchTypes "${WITH_BIN}" types
  mkdir -p "${target}"

  if test -n "${_GROOVY_SYS_HOME}" && test -d "${libDir}" && compgen -G "${libDir}/*.jar" >/dev/null; then
    info "scanning system groovy libs $(c 0Bui)${libDir}$(c 0i) ..."
    local jar base aid ver group type missing=0
    shopt -s nullglob
    for jar in "${libDir}"/*.jar; do
      case "${jar}" in *-sources.jar | *-javadoc.jar ) continue ;; esac
      base="$( basename "${jar}" .jar )"
      aid="${base%%-[0-9]*}"                                            # artifactId = up to the first -<digit>
      ver="${base#"${aid}-"}"                                           # version    = the remainder
      { test -n "${aid}" && test "${ver}" != "${base}"; } || continue   # no version (icns, etc.)
      group="$( resolveGroup "${aid}" )"
      test -n "${group}" || { info "  $(c 0Y)skip$(c 0i) unknown group: $(c 0G)${aid}-${ver}$(c)"; missing=$(( missing + 1 )); continue; }
      for type in "${types[@]}"; do
        test -f "${target}/${aid}-${ver}${type}.jar" && continue        # skip if present
        fetchJar "${MAVEN_BASE}/${group//.//}/${aid}/${ver}/${aid}-${ver}${type}.jar" "${target}"
      done
    done
    shopt -u nullglob
    test "${missing}" -eq 0 || info "$(c 0Y)${missing}$(c 0i) jar(s) unmapped; add them to $(c 0G)LIB_GROUP$(c) to include"
  else
    info "no system groovy libs at $(c 0Bui)${libDir}$(c 0i); fetching standard modules at $(c 0G)v${version}$(c) ..."
    info "  $(c 0Y)note$(c 0i): third-party deps can't be enumerated without a system install; groovy modules only"
    local m type
    for m in "${GROOVY_MODULES[@]}"; do
      for type in "${types[@]}"; do
        test -f "${target}/${m}-${version}${type}.jar" && continue
        fetchJar "${MAVEN_BASE}/org/apache/groovy/${m}/${version}/${m}-${version}${type}.jar" "${target}"
      done
    done
  fi
  linkLatest "${GROOVY_DIR}" "${version}"
}

# download an extension (bin+sources+javadoc) into <EXTENSIONS_DIR>/<artifact>/<version>, point latest
function installExtension() {
  local artifact="${1:?artifact is required}"
  local repo="${EXTENSION_REPO[${artifact}]:-${MAVEN_BASE}}"
  local group="${EXTENSION_GROUP[${artifact}]:-com/cloudbees}"
  local base="${EXTENSIONS_DIR}/${artifact}"
  local url="${repo}/${group}/${artifact}"
  local version
  if test -n "${EXTENSION_LTS[${artifact}]:-}"; then
    # weekly (X.Y) by default; --extension-lts → LTS (X.Y.Z)
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
  for type in "${types[@]}"; do
    fetchJar "${url}/${version}/${artifact}-${version}${type}.jar" "${target}"
  done
  linkLatest "${base}" "${version}"
}

function _parser() {
  local flag="$1"
  # nameref
  local -n _ver="$2"
  local argc="$3"
  local next="${4-}"

  # --groovy without version: defer to main() via the '@default' sentinel
  if [[ ${argc} -le 1 || "${next}" == -* ]]; then
    _ver='@default'
    return 1
  # --groovy 5.0.6
  elif [[ "${next}" =~ ^[0-9]+(\.[0-9]+)+([._-][a-zA-Z0-9]+)*$ ]]; then
    _ver="${next}"
    return 2
  else
    echo "ERROR: invalid version '${next}' for --${flag}" >&2
    exit 1
  fi
}

# print environment-setup hints
function printNotes() {
  local -a refLibs=() cliDirs=()
  # groovy/latest + extensions → referencedLibraries + classpath
  { test -n "${GROOVY_VERSION:-}" || "${WITH_LIBS}"; } && { refLibs+=( "${GROOVY_DIR}/latest/*" ); cliDirs+=( "${GROOVY_DIR}/latest" ); }
  local ext
  for ext in "${EXTENSIONS[@]}"; do refLibs+=( "${EXTENSIONS_DIR}/${ext}/latest/*" ); cliDirs+=( "${EXTENSIONS_DIR}/${ext}/latest" ); done
  [[ ${#refLibs[@]} -eq 0 ]] && return 0

  local refJoined cpJoined
  refJoined="$( printf '"%s", ' "${refLibs[@]}" )"; refJoined="${refJoined%, }"
  # classpath: <dir>/* = every jar in <dir>
  cpJoined="$( printf '%s/*:' "${cliDirs[@]}" )"; cpJoined="${cpJoined%:}"

  echo -e "$(show --bg --note ' NOTE ') $(c 0i)environment setup for the libraries above:$(c)"
  echo -e "  • nvim coc-groovy $(c 0Bui)~/.config/nvim/coc-settings.json $(c 0i)(LSP resolves against these jars):$(c)"
  echo -e "      $(c 0G)\"groovy.project.referencedLibraries\": [ ${refJoined} ]$(c)"
  echo -e "  • groovy CLI $(c 0Bui)~/.bashrc $(c 0i)(add the downloaded jars to the groovy/java classpath):$(c)"
  echo -e "      $(c 0G)export GROOVY_CLASSPATH=\"\${GROOVY_CLASSPATH:+\$GROOVY_CLASSPATH:}${cpJoined}\"$(c)"
  echo -e "      $(c 0G)export CLASSPATH=\"\${CLASSPATH:+\$CLASSPATH:}${cpJoined}\"$(c)"
}

# dedup EXTENSIONS, keep first-seen order
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

# --clean: remove version dirs + latest + extensions under ${GROOVY_DIR} (keeps the script)
function cleanEnv() {
  info "clean: removing groovy libs/runtime under $(c 0Bui)${GROOVY_DIR}$(c 0i) ..."
  local d count=0
  shopt -s nullglob
  for d in "${GROOVY_DIR}"/[0-9]* "${GROOVY_DIR}"/groovy-[0-9]* "${GROOVY_DIR}"/current \
           "${GROOVY_DIR}"/latest "${GROOVY_DIR}"/extensions \
           "${GROOVY_DIR}"/apache-groovy-binary-*.zip; do
    { test -e "${d}" || test -L "${d}"; } || continue
    rm -rf "${d}"
    info "  removed $(c 0G)${d}$(c)"
    count=$(( count + 1 ))
  done
  shopt -u nullglob
  info "removed $(c 0G)${count}$(c 0i) item(s)"
}

function main() {
  "${CLEAN}" && { cleanEnv; exit 0; }
  # --with-libs/--with-bin augment --jar; refuse them without --jar
  if { "${WITH_LIBS}" || "${WITH_BIN}"; } && test -z "${GROOVY_VERSION:-}"; then
    echo -e "$(show --bg --error 'ERROR') $(c 0i)$(c 0G)--with-libs$(c 0i)/$(c 0G)--with-bin$(c 0i) require $(c 0G)--jar$(c 0i) $(c 0Mi)[VERSION]$(c)" >&2
    exit 1
  fi
  dedupExtensions
  # detect the system groovy home (cross-platform) unless GROOVY_HOME already set it
  test -n "${_GROOVY_SYS_HOME}" || _GROOVY_SYS_HOME="$( detectGroovyHome || true )"
  # --runtime resolves its own version (latest stable, or --pre), never the system
  "${RUNTIME}"                  && installRuntime "${GROOVY_VERSION:-}"
  # resolve the deferred --jar default now that every flag (--latest/--pre) is parsed
  test '@default' = "${GROOVY_VERSION:-}" && GROOVY_VERSION="$( defaultVersion groovy )"
  test -n "${GROOVY_VERSION:-}" && groovy "${GROOVY_VERSION}"
  "${WITH_LIBS}"                && groovylibs "${GROOVY_VERSION}"
  local ext
  for ext in "${EXTENSIONS[@]}"; do installExtension "${ext}"; done

  echo -e "$(show --bg --note ' ✓ ') The libraries are ready!"
  printNotes
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --jar             ) _parser jar GROOVY_VERSION $# "${2-}"    ; shift $? ;;
    --groovy          ) _parser groovy GROOVY_VERSION $# "${2-}" ; shift $? ;;
    --runtime         ) RUNTIME=true        ; shift   ;;
    -l | --with-libs  ) WITH_LIBS=true      ; shift   ;;
    --with-bin        ) WITH_BIN=true       ; shift   ;;
    --pre             ) PRE=true            ; shift   ;;
    --latest          ) LATEST=true         ; shift   ;;
    --clean           ) CLEAN=true          ; shift   ;;
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
