#!/bin/bash

MAVENDIR="/opt/maven"
GRADLEDIR="/opt/gradle"
ARTIFACTORYURL="http://pww.artifactory.cdi.philips.com/artifactory"

[ ! -d ${MAVENDIR} ] && mkdir -p ${MAVENDIR}
[ ! -d ${GRADLEDIR} ] && mkdir -p ${GRADLEDIR}

wget ${ARTIFACTORYURL}/devops/common/maven/apache-maven-3.3.9-bin.tar.gz -P ${MAVENDIR}
tar xvzf ${MAVENDIR}/apache-maven-3.3.9-bin.tar.gz  -C ${MAVENDIR}

wget ${ARTIFACTORYURL}/devops/common/gradle/gradle-3.5-all.zip -P ${GRADLEDIR}
unzip ${GRADLEDIR}/gradle-3.5-all.zip -d ${GRADLEDIR}

sudo cp /etc/bashrc{,.org}
sudo bash -c 'cat >> /etc/bashrc' << EOF

# Setup by script
GRADLE_HOME="/opt/gradle/gradle-3.5"
M2_HOME="/opt/maven/apache-maven-3.3.9"
M2=\$M2_HOME/bin
MAVEN_OPTS="-Xms256m -Xmx512m"

PATH=\$M2:\$GRADLE_HOME/bin:\$PATH
export GRADLE_HOME M2_HOME M2 MAVEN_OPTS PATH

export LANG=en_US.UTF-8
export LANGUAGE=\$LANG
export LC_COLLATE=\$LANG
export LC_CTYPE=\$LANG
export LC_MESSAGES=\$LANG
export LC_MONETARY=\$LANG
export LC_NUMERIC=\$LANG
export LC_TIME=\$LANG
export LC_ALL=\$LANG
EOF
