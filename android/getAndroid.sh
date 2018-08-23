#!/bin/bash
# shellcheck disable=SC2046,SC1117,SC2009,SC2224,SC1078,SC1079
# =============================================================================
#   FileName: getAndroid.sh
#     Author: marslo
#      Email: marslo.jiao@gmail.com
#    Created: 2018-08-23 18:41:12
# LastChange: 2018-08-23 21:43:11
# =============================================================================

ANDROID_HOME=/opt/android
ANDROID_PLATFORMS=${ANDROID_HOME}/platforms
ANDROID_BUILDTOOLS=${ANDROID_HOME}/build-tools
ANDROID_TEMP=${ANDROID_HOME}/temp

ANDROID_REPO_URL="https://dl.google.com/android/repository"

SOCKSPORT="1880"
SOCKSSERVER="127.0.0.1"

CURL="/usr/bin/curl"
CURLOPT="-x socks5://${SOCKSSERVER}:${SOCKSPORT} --create-dirs -sSLo"

platformsList="""
android-16_r05.zip
android-17_r03.zip
android-18_r03.zip
android-20_r02.zip
android-22_r02.zip
platform-24_r02.zip
platform-27_r03.zip
android-19_r04.zip
android-21_r02.zip
platform-23_r03.zip
platform-26_r02.zip
platform-28_r06.zip
"""

buildtoolsList="""
build-tools_r26.0.2-linux.zip
build-tools_r25.0.3-linux.zip
build-tools_r25.0.2-linux.zip
build-tools_r25.0.1-linux.zip
build-tools_r25-linux.zip
build-tools_r24.0.3-linux.zip
build-tools_r24.0.2-linux.zip
build-tools_r24.0.1-linux.zip
build-tools_r24-linux.zip
build-tools_r23.0.3-linux.zip
build-tools_r23.0.2-linux.zip
build-tools_r23.0.1-linux.zip
build-tools_r22.0.1-linux.zip
build-tools_r21.1.2-linux.zip
build-tools_r20-linux.zip
build-tools_r19.1-linux.zip
"""
platformstools="platform-tools_r28.0.0-linux.zip"

# platform-tools
function getPlatformTools() {
  if [ ! -e  ${ANDROID_TEMP}/${platformstools} ]; then
    ${CURL} ${CURLOPT} ${ANDROID_TEMP}/${platformstools} ${ANDROID_REPO_URL}/${platformstools}
  fi
  unzipPlatformTools
}
function unzipPlatformTools()
{
  [ ! -d  ${ANDROID_HOME}/platform-tools ] && unzip -q ${ANDROID_TEMP}/platform-tools_r28.0.0-linux.zip -d ${ANDROID_HOME}/
}

# build-tools
function getBuildTools()
{
  for bt in ${buildtoolsList}; do
    if [ ! -e ${ANDROID_TEMP}/${bt} ]; then
      ${CURL} ${CURLOPT} ${ANDROID_TEMP}/${bt} ${ANDROID_REPO_URL}/${bt}
    fi
  done
  unzipBuildTools
}
function unzipBuildTools()
{
  [ -d ${tempf} ] && rm -rf ${tempf}
  tempf="${ANDROID_TEMP}/btfolder"

  for bt in ${buildtoolsList}; do
    curver=$(echo ${bt} | sed -re "s:^.*_r([0-9\.]*)-.*$:\1:")
    if [ 0 -eq $(echo "${curver}" | awk -F'.' '{print NF-1}') ]; then
      curver=${curver}.0.0
    elif [ 1 -eq $(echo "${curver}" | awk -F'.' '{print NF-1}') ]; then
      curver=${curver}.0
    fi

    if [ ! -d  ${ANDROID_BUILDTOOLS}/${curver} ]; then
      unzip -q ${ANDROID_TEMP}/${bt} -d ${tempf}
      mv ${tempf}/* ${ANDROID_BUILDTOOLS}/${curver}
    fi
  done
}

# platforms
function getPlatforms()
{
  for pl in ${platformsList}; do
    if [ ! -e ${ANDROID_TEMP}/${pl} ]; then
      ${CURL} ${CURLOPT} ${ANDROID_TEMP}/${pl} ${ANDROID_REPO_URL}/${pl}
    fi
  done
  unzipPlatforms
}
function unzipPlatforms()
{
  tempf="${ANDROID_TEMP}/plfolder"
  [ -d ${tempf} ] && rm -rf ${tempf}

  for pl in ${platformsList}; do
    plname="android-$(echo ${pl} | sed -re "s:^.*-([0-9]*)_.*$:\1:")"
    if [ ! -d ${ANDROID_PLATFORMS}/${plname} ]; then
      unzip -q ${ANDROID_TEMP}/${pl} -d ${tempf}
      mv ${tempf}/* ${ANDROID_PLATFORMS}/${plname}
    fi
  done
}

function clrTemp()
{
  rm -rf ${ANDROID_TEMP}
}

function getAndroid() {
  getPlatformTools
  getBuildTools
  getPlatforms
}

for adir in ${ANDROID_HOME} ${ANDROID_PLATFORMS} ${ANDROID_BUILDTOOLS} ${ANDROID_TEMP}; do
  [ ! -d ${adir} ] && mkdir -p ${adir}
done
