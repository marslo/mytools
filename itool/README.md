
## groovy-libs.sh

```bash
# download/setup
$ cp groovy-libs.sh /opt/groovy
$ bash /opt/groovy/groovy-libs.sh --groovy --groovy-libs --jenkins
```

## jenkins-libs.sh

```bash
$ cp jenkins-libs.sh /opt/jenkins
$ bash /opt/jenkins/jenkins-libs.sh --lts --ln
```

## environment variable

```bash
# ~/.bash_profile or ~/.bashrc
JAVA_HOME=$(/usr/libexec/java_home)                             # $ sudo ln -sfn $(brew --prefix openjdk)/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
GROOVY_HOME="${HOMEBREW_OPT}/groovy/libexec"                    # -> "${HOMEBREW_OPT}/groovy/libexec"
_GROOVY_LIBS='/opt/groovy/libs'
_JENKINS_LIBS='/opt/jenkins'
# GROOVY_HOME="/opt/groovy/current"                             # -> for groovydoc issue
GROOVY_CLASSPATH="${GROOVY_CLASSPATH:+$GROOVY_CLASSPATH:}"
test -d "${GROOVY_HOME}/lib"                  && GROOVY_CLASSPATH+=".:$(echo "${GROOVY_HOME}"/lib/*.jar | tr ' ' ':'):"
test -d "${_GROOVY_LIBS}/groovy"              && GROOVY_CLASSPATH+="$(echo "${_GROOVY_LIBS}"/groovy/latest/*.jar | tr ' ' ':'):"
test -d "${_GROOVY_LIBS}/jenkins"             && GROOVY_CLASSPATH+="$(echo "${_GROOVY_LIBS}"/jenkins/latest/*.jar | tr ' ' ':'):"
test -d "${_JENKINS_LIBS}/latest/WEB-INF/lib" && GROOVY_CLASSPATH+="$(echo "${_JENKINS_LIBS}"/latest/WEB-INF/lib/*.jar | tr ' ' ':'):"
test -d "${_JENKINS_LIBS}/plugins"            && GROOVY_CLASSPATH+="$(echo "${_JENKINS_LIBS}"/plugins/*/latest/WEB-INF/lib/*.jar | tr ' ' ':')"
test -f "${HOMEBREW_OPT}/coreutils/libexec/gnubin/paste" &&
     GROOVY_CLASSPATH=$( echo "${GROOVY_CLASSPATH}" | tr ':' '\n' | awk 'NF' | awk '!x[$0]++' | "${HOMEBREW_OPT}/coreutils/libexec/gnubin/paste" -s -d: )
test -f "${JAVA_HOME}/lib/tools.jar"          && GROOVY_CLASSPATH+=":${JAVA_HOME}/lib/tools.jar"
test -f "${JAVA_HOME}/lib/dt.jar"             && GROOVY_CLASSPATH+=":${JAVA_HOME}/lib/dt.jar"
CLASSPATH+=":${GROOVY_CLASSPATH}"
test -f "${HOMEBREW_OPT}/coreutils/libexec/gnubin/paste" &&
     CLASSPATH=$( echo "${CLASSPATH}" | tr ':' '\n' | awk 'NF' | awk '!x[$0]++' | "${HOMEBREW_OPT}/coreutils/libexec/gnubin/paste" -s -d: )
unset _GROOVY_LIBS _JENKINS_LIBS
```

```jsonc
// ~/.config/nvim/coc-settings.json
{
  "groovy.enable": true,
  "groovy.java.home": "/opt/homebrew/Cellar/openjdk@21/21.0.12/libexec/openjdk.jdk/Contents/Home",
  "groovy.project.referencedLibraries": [
    "/opt/groovy/libs/groovy/latest/*",
    "/opt/groovy/libs/jenkins/latest/*",
    "/opt/homebrew/opt/groovy/libexec/lib/*",
    "/Users/marslo/.groovy/lib/*",
    "/opt/jenkins/latest/WEB-INF/lib/*"
  ],
  "groovy.ls.vmargs": "-noverify -Xmx2G -XX:+UseG1GC -XX:+UseStringDeduplication",
  "groovy.trace.server": "off",
  "groovy.ls.feature.noRoot": true
}
```
