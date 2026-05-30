#!/usr/bin/env bash
# =============================================================================
#      FileName : jardownload.sh
#        Author : marslo
#       Created : 2026-05-29 23:20:19
#    LastChange : 2026-05-30 01:31:05
# =============================================================================

function groovy() {
  version="${1:-5.0.6}"
  GROOVY_REPO="https://repo1.maven.org/maven2/org/apache/groovy/groovy/${version}"

  echo "Downloading Groovy ${version} ..."
  cd "${GROOVY_DIR}" || exit
  for type in "" "-sources" "-javadoc"; do
    "${CURL[@]}" "${GROOVY_REPO}/groovy-${version}${type}.jar"
  done
}

function groovylibs() {
  local version="${1:-5.0.6}"
  cd "${GROOVY_DIR}" || exit

  while read -r module _version; do
    echo "Downloading ${module} ${version} (system using ${_version}) ..."
    local repo="https://repo1.maven.org/maven2/org/apache/groovy/${module}/${version}"

    for type in '' '-sources' '-javadoc'; do
      "${CURL[@]}" "${repo}/${module}-${version}${type}.jar"
    done
  done< <( /bin/ls --color=never -1 "${GROOVYH_HOME:-/opt/homebrew/opt/groovy/libexec}"/lib/groovy-*.jar | sed -nE 's:^.*/([^/]+.)-([0-9.]+)\.jar:\1 \2:p' )
}

function jenkins() {
  local version="${1:-2.555.2}"
  local repo="https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-core/${version}"

  echo "Downloading Jenkins Core ${version} ..."
  cd "${JENKINS_DIR}" || exit

  for type in "" "-sources" "-javadoc"; do
    "${CURL[@]}" "${repo}/jenkins-core-${version}${type}.jar"
  done
}

function _parser() {
  local flag="$1"
  # nameref
  local -n _ver="$2"
  local default="$3"
  local argc="$4"
  local next="${5-}"

  # --java --jenkins -> without version, use default
  if [[ ${argc} -le 1 || "${next}" == -* ]]; then
    _ver="${default}"
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

function main() {
  mkdir -p "${GROOVY_DIR}" "${JENKINS_DIR}"

  test -n "${GROOVY_VERSION:-}"  && groovy "${GROOVY_VERSION}"
  test -n "${JENKINS_VERSION:-}" && jenkins "${JENKINS_VERSION}"
  "${GROOVYLIBS}" && groovylibs "${GROOVY_VERSION}"

  echo '>> Done! The flat libraries are ready!'
}

declare _DEFAULT_DESTINATION='/opt/groovy/global-libs'
declare _GROOVY_VERSION='5.0.6'
declare _JENKINS_VERSION='2.555.2'
declare -a CURL=( 'curl' '-sSLfO' )
declare GROOVYLIBS=false
declare -r USAGE="NAME
  $0 - Download Groovy and Jenkins Core libraries and their sources and javadocs

USAGE
  \$ $0 [OPTIONS]

OPTIONS
  --groovy \033[0;2;3;37mVERSION\033[0m        download the Groovy library. Optionally specify the version (default: ${_GROOVY_VERSION})
  --jenkins \033[0;2;3;37mVERSION\033[0m       download the Jenkins Core library. Optionally specify the version (default: ${_JENKINS_VERSION})
  --groovylibs            download the Groovy libraries
  -p, --path \033[0;2;3;37mDESTINATION\033[0m  specify the destination directory (default: ${_DEFAULT_DESTINATION})
  -h, --help              show this help message and exit

EXAMPLE
  \033[0;2;3;37m# download groovy 6.0.1, jenkins 2.566 jar files and groovy libs\033[0m
  \$ $0 --groovy 6.0.1 --jenkins 2.566 --groovylibs

  \033[0;2;3;37m# download groovy and jenkins jar files with default version (5.0.6, 2.555.2) to path '/tmp/libs'\033[0m
  \$ $0 --groovy --jenkins --path /tmp/libs
"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --groovy     ) _parser groovy  GROOVY_VERSION  "${_GROOVY_VERSION}"  $# "${2-}" ; shift $? ;;
    --jenkins    ) _parser jenkins JENKINS_VERSION "${_JENKINS_VERSION}" $# "${2-}" ; shift $? ;;
    --groovylibs ) GROOVYLIBS=true  ; shift   ;;
    -p | --path  ) DESTINATION="$2" ; shift 2 ;;
    -h | --help  ) echo -e "${USAGE}" >&2; exit 0 ;;
    *            ) echo "ERROR: unknown option '$1'"; exit 1;;
  esac
done

DESTINATION="${DESTINATION:-${_DEFAULT_DESTINATION}}"
declare GROOVY_DIR="${DESTINATION}/groovy"
declare JENKINS_DIR="${DESTINATION}/jenkins"

main "$@"

# vim:tabstop=2:softtabstop=2:shiftwidth=2:expandtab:filetype=sh:
