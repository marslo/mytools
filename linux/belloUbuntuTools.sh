#!/bin/bash
# shellcheck disable=SC2015
# =============================================================================
#    FileName: belloUbuntuTools.sh
#      Author: marslo.jiao@gmail.com
#     Created: 2018-01-18 20:42:27
#  LastChange: 2018-04-01 12:41:51
# =============================================================================
# USAGE:
#     please repace the GITLABHOST, SONARURL and ARTIFACTORYHOST to your own situation

MAVENDIR="/opt/maven"
GRADLEDIR="/opt/gradle"
SONARDIR="/opt/sonarqube"
JAVADIR="/opt/java"
JAVAHOME="${JAVADIR}/jdk1.8.0_162"
DOCKERDIR="/opt/docker"
DOCKERCONF="$HOME/.docker/config.json"
DOCKERDAEMON="$HOME/.docker/daemon.json"
TIMESTAMPE=$(date +"%Y%m%d%H%M%S")

ARTIFACTORYHOST="www.myartifactory.com"
GITLABHOST="www.mygitlab.com"
ARTIFACTORYURL="http://${ARTIFACTORYHOST}/artifactory"
SONARURL="http://www.mysonar.com:9000"

function reportError(){
  set +H
  echo -e "\\033[31mERROR: $1 !!\\033[0m"
  set -H
}

function doMaven() {
  if ! mvn --version > /dev/null 2>&1; then
    wget ${ARTIFACTORYURL}/devops/common/maven/apache-maven-3.3.9-bin.tar.gz -P ${MAVENDIR}
    tar xvzf ${MAVENDIR}/apache-maven-3.3.9-bin.tar.gz -C ${MAVENDIR}
    sudo update-alternatives --install /usr/local/bin/mvn mvn ${MAVENDIR}/apache-maven-3.3.9/bin/mvn 99
    sudo update-alternatives --auto mvn
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
    sudo update-alternatives --install /usr/local/bin/gradle gradle ${GRADLEDIR}/gradle-3.5/bin/gradle 99
    sudo update-alternatives --auto gradle
    if ! gradle --version; then
      reportError "gradle 3.5 installed failed"
    fi
  fi

  if ! gradle3.3 --version > /dev/null 2>&1; then
    curl ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.3-all.zip --create-dirs -o ${GRADLEDIR}/gradle-3.3-all.zip
    unzip ${GRADLEDIR}/gradle-3.3-all.zip -d ${GRADLEDIR}
    sudo update-alternatives --install /usr/local/bin/gradle3.3 gradle3.3 ${GRADLEDIR}/gradle-3.3/bin/gradle 99
    sudo update-alternatives --auto gradle3.3
    gradleSetup
    if ! gradle3.3 --version; then
      reportError "gradle 3.3 installed failed"
    fi
  fi

  which -a gradle
  which -a gradle3.3
}

function gradleSetup() {
  [ -f ~/.gradle/gradle.properties ] && mv ~/.gradle/gradle.properties{,.bak.${TIMESTAMPE}} || mkdir -p ~/.gradle
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
    sudo chown -R "$(whoami)":root /usr/local/n
    npmSetup
  fi
}

function npmSetup() {
  if ! npm --version > /dev/null 2>&1; then
    [ -f ~/.npmrc ] && mv ~/.npmrc{,.org.${TIMESTAMPE}}
    echo "registry=http://${ARTIFACTORYHOST}/artifactory/api/npm/npm-snapshot/" > ~/.npmrc
    echo "progress=false" >> ~/.npmrc
    sudo chown -R "$(whoami)":root /usr/local

    n latest
    n lts
    n 6.10.3
    n 7.10.0

    npm i -g npm@latest
    # npm i -g ionic increase-memory-limit cordova json-server
    # or
    # npm i -g ionic@3.15.2 increase-memory-limit@1.0.5 cordova@7.1.0 json-server
    if ! npm --version; then
      reportError "npm install failed"
    fi
  fi
}


function doJava() {
  if ! java -version; then
    curl ${ARTIFACTORYURL}/devops/common/java/jdk-8u162-linux-x64.tar.gz --create-dirs -o ${JAVADIR}/jdk-8u162-linux-x64.tar.gz
    tar xvzf ${JAVADIR}/jdk-8u162-linux-x64.tar.gz -C ${JAVADIR}
    javaSetup
    if ! java -version; then
      reportError "java installed failed"
    fi
    javac -version
  fi

  which -a javac
  which -a java
}

function javaSetup() {
  sudo update-alternatives --install /usr/local/bin/java    java    ${JAVAHOME}/bin/java    99
  sudo update-alternatives --install /usr/local/bin/javac   javac   ${JAVAHOME}/bin/javac   99
  sudo update-alternatives --install /usr/local/bin/javah   javah   ${JAVAHOME}/bin/javah   99
  sudo update-alternatives --install /usr/local/bin/javap   javap   ${JAVAHOME}/bin/javap   99
  sudo update-alternatives --install /usr/local/bin/javadoc javadoc ${JAVAHOME}/bin/javadoc 99
  sudo update-alternatives --auto java
  sudo update-alternatives --auto javac
  sudo update-alternatives --auto javah
  sudo update-alternatives --auto javap
  sudo update-alternatives --auto javadoc
}

function doDocker() {
  if ! docker --version > /dev/null 2>&1; then
    sudo apt install docker-ce
    dockerSetup
  fi
}

function dockerSetup() {
  sudo killall Docker
  [ -f ${DOCKERCONF} ] && mv ${DOCKERCONF}{,.bak.${TIMESTAMPE}}
  [ -f ${DOCKERDAEMON} ] && mv ${DOCKERDAEMON}{,.bak.${TIMESTAMPE}}

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
  sudo cp ${ARTIFACTORYHOST}-ca.crt /usr/local/share/ca-certificates/
  ls -Altrh !$
  sudo update-ca-certificates
  sudo systemctl restart docker.service
  sleep 5
  if ! pgrep -f docker; then
    reportError "docker start failed"
  fi
}

function doSonar() {
  if ! sonar-scanner --version > /dev/null 2>&1; then
    curl ${ARTIFACTORYURL}/devops/sca/sonar-scanner-cli-3.0.3.778-linux.zip --create-dirs -o ${SONARDIR}/sonar-scanner-3.0.3.zip
    unzip ${SONARDIR}/sonar-scanner-3.0.3.zip -d ${SONARDIR}
    mv ${SONARDIR}/sonar-scanner-3.0.3.778-linux ${SONARDIR}/sonar-scanner-3.0.3
    sudo update-alternatives --install /usr/local/bin/sonar-scanner sonar-scanner ${SONARDIR}/sonar-scanner-3.0.3/bin/sonar-scanner 99
    sudo update-alternatives --auto sonar-scanner
    sonarSetup
    if ! sonar-scanner --version; then
      reportError "sonar-scanner installed failed"
    fi
  fi

  which -a sonar-scanner
}

function sonarSetup() {
  [ -f ${SONARDIR}/sonar-scanner-3.0.3/conf/sonar-scanner.properties ] && mv ${SONARDIR}/sonar-scanner-3.0.3/conf/sonar-scanner.properties{,.bak.${TIMESTAMPE}}
  cat > ${SONARDIR}/sonar-scanner-3.0.3/conf/sonar-scanner.properties << EOF
#----- Default SonarQube server
sonar.host.url=${SONARURL}

#----- Default source code encoding
sonar.sourceEncoding=UTF-8

sonar.login=5e458048fdc7b8fc39e8ec15f300b50d4f8db111
EOF
}

function jenkinsBasicEnv() {
  cd ~
  git clone git@${GITLABHOST}:devops_home/env.git
  scp -r slave02:~/.ssh/slave@devops* ~/.ssh/
}

function reSetupTools(){
  javaSetup
  gradleSetup
  mavenSetup
  dockerSetup
  npmSetup
  sonarSetup
}

function setupUbuntuTools() {
  doJava
  doGradle
  doMaven
  doDocker
  doNpm
  doSonar
  jenkinsBasicEnv
}

sudo chown -R "$(whoami)":"$(whoami)" /opt
setupUbuntuTools
# reSetupTools
