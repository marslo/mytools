# =============================================================================
#   FileName: removeMavenMetadata.sh
#     Author: marslo
#      Email: marslo.jiao@gmail.com
#    Created: 2018-08-24 16:44:40
# LastChange: 2018-08-24 16:44:40
# =============================================================================

ARTIFACTORYURL="http://my.artifactory.com/artifactory"
REPONAME="gradle-dev-local"
FILENAME="maven-metadata.xml"
fileList=$(curl -s -g -k ${ARTIFACTORYURL}/api/search/artifact?name=${FILENAME}\&repos=${REPONAME} | jq '.results[].uri')

echo ${fileList}
