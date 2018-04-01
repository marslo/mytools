#!/bin/bash
# shellcheck disable=SC2015
# =============================================================================
#    FileName: belloOSXTools.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2018-01-18 20:42:27
#  LastChange: 2018-03-28 20:55:41
# =============================================================================

MAVENDIR="/opt/maven"
GRADLEDIR="/opt/gradle"
SONARDIR="/opt/sonarqube"
JAVADIR="/opt/java"
DOCKERDIR="/opt/docker"
DOCKERCONF="$HOME/.docker/config.json"
DOCKERDAEMON="$HOME/.docker/daemon.json"
GITLABHOST="www.my.company"
ARTIFACTORYHOST="www.my.company"
ARTIFACTORYURL="http://${ARTIFACTORYHOST}/artifactory"
SONARURL="http://my.sonar.com:9000"
TIMESTAMPE=$(date +"%Y%m%d%H%M%S")

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function doMaven() {
  if ! mvn --version > /dev/null 2>&1; then
    wget ${ARTIFACTORYURL}/devops/common/maven/apache-maven-3.3.9-bin.tar.gz -P ${MAVENDIR}
    tar xvzf ${MAVENDIR}/apache-maven-3.3.9-bin.tar.gz -C ${MAVENDIR}
    mavenSetup
    if ! mvn --version; then
      reportError "mvn installed failed"
    fi
  fi

  which -a mvn
}

function mavenSetup() {
  [ -f ~/.m2/settings.xml ] && mv ~/.m2/settings.xml{,.org.${TIMESTAMPE}} || mkdir -p ~/.m2
  curl ${ARTIFACTORYURL}/devops/common/settings.xml --create-dirs -o ~/.m2/settings.xml
}

function doGradle() {
  if ! gradle --version > /dev/null 2>&1; then
    curl ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.5-all.zip --create-dirs -o ${GRADLEDIR}/gradle-3.5-all.zip
    unzip ${GRADLEDIR}/gradle-3.5-all.zip -d ${GRADLEDIR}
    gradleSetup
    if ! gradle --version; then
      reportError "gradle 3.5 installed failed"
    fi
  fi

  if ! gradle3.3 --version > /dev/null 2>&1; then
    curl ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.3-all.zip --create-dirs -o ${GRADLEDIR}/gradle-3.3-all.zip
    unzip ${GRADLEDIR}/gradle-3.3-all.zip -d ${GRADLEDIR}
    if ! gradle3.3 --version; then
      reportError "gradle 3.3 installed failed"
    fi
  fi

  which -a gradle
  which -a gradle3.3
}

function gradleSetup() {
  [ -f ~/.gradle/gradle.properties ] && mv ~/.gradle/gradle.properties{,.bak} || mkdir -p ~/.gradle
  cat > ~/.gradle/gradle.properties << EOF
org.gradle.daemon=false
org.gradle.jvmargs=-Xmx2048M
artifactory_contextUrl=${ARTIFACTORYURL}
systemProp.sonar.host.url=${SONARURL}
systemProp.sonar.login=ab170a6d81e17267c94c319ef2ded13a3da7155b
EOF
}

function doNpm() {
  if ! n --version > /dev/null 2>&1; then
    git clone https://github.com/tj/n /opt/n
    cd /opt/n
    make install
    sudo chown -R "$(whoami)":wheel /usr/local/n
    if ! n --version; then
      reportError "n installed failed"
    fi
  fi
  npmSetup
}

function npmSetup() {
  if ! npm --version > /dev/null 2>&1; then
    [ -f ~/.npmrc ] && mv ~/.npmrc{,.org}
    echo "registry=${ARTIFACTORYURL}/api/npm/npm-snapshot/" > ~/.npmrc
    echo "progress=false" >> ~/.npmrc
    sudo chown -R "$(whoami)":admin /usr/local

    n latest
    n lts
    n 6.10.3
    n 7.10.0

    npm i -g npm@latest
    # npm i -g ionic increase-memory-limit cordova json-server
    # or
    # npm i -g ionic@3.15.2 increase-memory-limit@1.0.5 cordova@7.1.0 json-server
  fi
}


function doJava() {
  if ! java -version; then
    curl ${ARTIFACTORYURL}/devops/iOS/java/jdk-8u161-macosx-x64.dmg --create-dirs -o ${JAVADIR}/jdk-8u161-macosx-x64.dmg
    diskutil list
    hdiutil attach ${JAVADIR}/jdk-8u161-macosx-x64.dmg
    sudo installer -verbose -pkg "/Volumes/JDK 8 Update 161/JDK 8 Update 161.pkg" -target /
    hdiutil unmount "/Volumes/JDK 8 Update 161" -force
    hdiutil detach "/Volumes/JDK 8 Update 161"
    diskutil list
    /usr/libexec/java_home -v 1.8.0.161 --exec javac -version

    if ! java -version; then
      reportError "java installed failed"
    fi
    javac -version
  fi

  which -a javac
  which -a java
}

function doDocker() {
  if ! docker --version > /dev/null 2>&1; then
    curl ${ARTIFACTORYURL}/devops/docker/Docker-stable-17.12.0-ce-mac49.dmg --create-dirs -o ${DOCKERDIR}/Docker-stable-17.12.0-ce-mac49.dmg
    diskutil list
    hdiutil attach ${DOCKERDIR}/Docker-stable-17.12.0-ce-mac49.dmg
    cp -r /Volumes/Docker/Docker.app /Applications/
    hdiutil unmount /Volumes/Docker -force
    hdiutil eject /Volumes/Docker
    diskutil list
    open --hide --background -a Docker
    dockerSetup
  fi
}

function dockerSetup() {
  [ -f ${DOCKERCONF} ] && mv ${DOCKERCONF}{,.bak.${TIMESTAMPE}}
  [ -f ${DOCKERDAEMON} ] && mv ${DOCKERDAEMON}{,.bak.${TIMESTAMPE}}

  # disable the "credsStore": "osxkeychain"
  sudo killall Docker
  sed -i -e "/^.*credsStore.*$/ d" ${DOCKERCONF}
  linenumber=$(( $(sed -n '$=' ${DOCKERCONF}) - 1))
  sed -i -e "${linenumber}c }" ${DOCKERCONF}

  # setup allow-nondistributable-artifacts in ~/.docker/daemon.json
  sed -i -e '$d' ${DOCKERDAEMON}
  sed -i -e "s:\\(^.*$\\):\\1,:" ${DOCKERDAEMON}
  cat >> ${DOCKERDAEMON} << EOF
  "allow-nondistributable-artifacts" : ['
    "${ARTIFACTORYHOST}",'
    "${ARTIFACTORYHOST}:443"'
   ]'
  }'
EOF

  # setup the cdi Artifactory ssl credential
  curl ${ARTIFACTORYURL}/devops/docker/${ARTIFACTORYHOST}-ca.crt --create-dirs -o ${DOCKERDIR}/${ARTIFACTORYHOST}-ca.crt
  sudo security add-trusted-cert -d -r trustRoot -k "/Library/Keychains/System.keychain" "${DOCKERDIR}/${ARTIFACTORYHOST}-ca.crt"
  security find-certificate -a -Z -c artifactory | grep SHA-1
  sudo killall Docker && sleep 5 && open --hide --background -a Docker

  sleep 10
  if ! pgrep -f docker; then
    reportError "docker start failed"
  fi
}

function doSonar() {
  if ! sonar-scanner --version > /dev/null 2>&1; then
    curl ${ARTIFACTORYURL}/devops/sca/sonar-scanner-cli-3.0.3.778-macosx.zip --create-dirs -o ${SONARDIR}/sonar-scanner-3.0.3.zip
    unzip ${SONARDIR}/sonar-scanner-3.0.3.zip -d ${SONARDIR}
    mv ${SONARDIR}/sonar-scanner-3.0.3.778-macosx ${SONARDIR}/sonar-scanner-3.0.3
    sonarSetup

    if ! sonar-scanner --version; then
      reportError "sonar-scanner installed failed"
    fi
  fi

}

function sonarSetup() {
  [ -f ${SONARDIR}/sonar-scanner-3.0.3/conf/sonar-scanner.properties ] && mv ${SONARDIR}/sonar-scanner-3.0.3/conf/sonar-scanner.properties{,.bak}
  cat > ${SONARDIR}/sonar-scanner-3.0.3/conf/sonar-scanner.properties << EOF
#----- Default SonarQube server
sonar.host.url=http://${SONARURL}

#----- Default source code encoding
sonar.sourceEncoding=UTF-8

sonar.login=5e458048fdc7b8fc39e8ec15f300b50d4f8db111
EOF
}

function jenkinsBasicEnv() {
  cd ~
  git clone git@${GITLABHOST}:devops_home/env.git
  scp -r slave02:~/.ssh ~
}

function reSetupTools(){
  gradleSetup
  mavenSetup
  dockerSetup
  npmSetup
  sonarSetup
}

function doOSXTools() {
  doJava
  doGradle
  doMaven
  doDocker
  doNpm
  doSonar
  jenkinsBasicEnv
}

sudo chown -R "$(whoami)":"$(whoami)" /opt
doOSXTools
# reSetupTools
