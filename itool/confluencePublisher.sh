#!/bin/bash
# =============================================================================
#   FileName: confluencePublisher.sh
#     Author: marslo.jiao@gmail.com
#    Created: 2020-08-19 22:28:24
# LastChange: 2020-08-19 22:29:15
# =============================================================================

temp='a.json'
pageID='12345'
domain='my.confluence.com'
html='index.html'

url="https://${domain}/rest/api/content/${pageID}"
page=$(curl -sn ${url})
space=$(echo "${page}" | jq .space.key)
title=$(echo "${page}" | jq .title)
currentVer=$(echo "${page}" | jq .version.number)
newVer=$((currentVer+1))

cleanEnv() {
  [ -f "${temp}" ] && rm -rf ${temp}
}

echo "content length: $(cat $html | xargs | wc -m)"
cleanEnv
cat > ${temp} << EOF
{
  "id": "${pageID}",
  "type": "page",
  "title": ${title},
  "space": {"key": ${space}},
  "body": {
    "storage": {
      "value": "$(cat ${html} | xargs)",
      "representation": "storage"
    }
  },
  "version": {"number":${newVer}}
}
EOF

curl -sn -X PUT -H 'Content-Type: application/json' --data "$(cat ${temp})" ${url}
echo "visit the page at https://${domain}/pages/viewpage.action?pageId=${pageID}"
