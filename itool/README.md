<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [groovy-libs.sh](#groovy-libssh)
- [jenkins-libs.sh](#jenkins-libssh)
- [lsp-gdoc](#lsp-gdoc)
- [environment variable](#environment-variable)
- [vimrc & coc-settings.json](#vimrc--coc-settingsjson)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## groovy-libs.sh

```bash
# download <name>-sources.jar and <name>-javadoc.jar
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --groovy --with-libs --path /opt/groovy

#                                                                                                      + <name>-sources.jar and <name>-javadoc.jar
#                                                                                                      v           + <name>.jar
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --groovy --with-libs --with-bin --path /opt/groovy

# ── to cleanup ──
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/groovy-libs.sh | bash -s -- --clean
```

## jenkins-libs.sh

```bash
#                                                                                                  + ln -sf to ~/.groovy/lib
#                                                                                                  |      + <name>-sources.jar
#                                                                                                  v      v       + <name>-javadoc.jar
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/jenkins-libs.sh | bash -s -- --lts --ln --sources --javadoc --path /opt/jenkins

# ── to cleanup ──
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/jenkins-libs.sh | bash -s -- --clean
```

## lsp-gdoc
```bash
# - sources.jar : unzip '*.java''*.groovy' ----►  ~/.cache/nvim/gdoc/src/  -- ctags --►  ~/.cache/nvim/gdoc/.tags
# - javadoc.jar : (list HTML manifest ONLY) ---►  ~/.cache/nvim/gdoc/javadoc-map.tsv
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/lsp-gdoc | bash -s -- --build

# ── to cleanup ──
$ curl -fsSL https://github.com/marslo/mytools/raw/main/itool/lsp-gdoc | bash -s -- --clean
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

## vimrc & coc-settings.json

```jsonc
// ~/.config/nvim/coc-settings.json
{
  "groovy.enable": true,
  "groovy.java.home": "/opt/homebrew/Cellar/openjdk@21/21.0.12/libexec/openjdk.jdk/Contents/Home",
  "groovy.project.referencedLibraries": [
    "/opt/homebrew/opt/groovy/libexec/lib/*",                     // brew install groovy
    "/opt/groovy/latest/*",                                       // groovy-libs.sh --groovy --with-libs
    "/opt/jenkins/latest/WEB-INF/lib/*",                          // jenkins-libs.sh --lts --sources --groovydcoc
    "/Users/marslo/.groovy/lib/*"                                 // jenkins-libs.sh [OPTION] --ln
  ],
  "groovy.ls.vmargs": "-noverify -Xmx2G -XX:+UseG1GC -XX:+UseStringDeduplication",
  "groovy.trace.server": "off",
  "groovy.ls.feature.noRoot": true
}
```

```vim
" ~/.vimrc
augroup Groovy
  autocmd FileType groovy,Jenkinsfile setlocal tags+=~/.cache/nvim/gdoc/.tags
augroup END

augroup JavaMarkdownDoc
  autocmd!
  autocmd ColorScheme * highlight default link markdownLineStart markdownH1
augroup END
silent! highlight default link markdownLineStart markdownH1
```
