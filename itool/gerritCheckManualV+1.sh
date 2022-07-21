#!/usr/bin/env bash
# shellcheck disable=SC2089,SC2090

hostname='gerrit.mycompany.com'
path='a/b/c'
url="https://${hostname}/a/changes/$(echo "${path}" | sed -n 's:/:%2F:gp')"
branch='master'
account='service-accunt'
dir='/home/marslo/path/to/repo'

curlOpt='curl -sg --netrc-file ~/.netrc'
sinced='2022-01-01'

for revision in $(git -C "${dir}" log --since="${sinced}" --pretty=format:"%H"); do
  exist=$(curl -s --netrc-file ~/.marslo/.netrc -o /dev/null -w "%{http_code}" "${url}~${branch}~${changeId}")
  if [ '200' = "${exist}" ]; then
    changeId=$(git -C "${dir}" show "${revision}" --no-patch --format="%s%n%n%b" | sed -nre 's!Change-Id: (.*$)!\1!p')
    # gProject=$(eval "${curlOpt} -X GET ${url}~${branch}~${changeId}"    | tail -n +2 | jq -r .project)
    status=$(eval "${curlOpt} -X GET ${url}~${branch}~${changeId}"        | tail -n +2 | jq -r .status)
    voter=$(eval "${curlOpt}  -X GET ${url}~${branch}~${changeId}/detail" | tail -n +2 | jq -r .labels.Verified.approved.username)
    owner=$(eval "${curlOpt}  -X GET ${url}~${branch}~${changeId}/detail" | tail -n +2 | jq -r .owner.username)
    if [ 'MERGED' = "${status}" ] && [ "${account}" != "${voter}" ]; then
      echo """
        ~~~~~>
                    voter : ${voter}
                 changeId : ${changeId}
                    owner : ${owner}
                 reivsion : ${revision}
               authorDate : $(git -C "${dir}" show "${revision}" --no-patch --format="%ad" | head)
            commitMessage : $(git -C "${dir}" show "${revision}" --no-patch --format="%s"  | head)
      """
    fi
  fi
done


# for rev in $(git -C "${dir}" log --since="${sinced}" --pretty=format:"%H"); do
  # cid=$(git -C "${dir}" show "${rev}" --no-patch --format="%s%n%n%b" | sed -nre 's!Change-Id: (.*$)!\1!p')
  # vuser=$(curl -s -X GET --user "${user}:${passwd}" "${url}~${br}~${cid}/detail" | tail -n +2 | jq .labels.Verified.approved.username)
  # if [ "${funcuser}" != "${vuser}" ]; then
    # git -C "${dir}" show "${rev}" --no-patch --format="%ad%n%snb" | head
    # echo "~~~~ ${rev}: ${cid}: ${vuser}"
    # echo ""
  # fi
# done
