vgit='gerrit.mycompany.com'
url="https://${vgit}/a/changes/myproject"
br='master'
funcuser='func-user'
sinced='2019-11-01'

dir='/Users/marslo/mywork/job/code/workspace'
user='marslo'
passwd='marslo-passwd'

for rev in $(git -C "${dir}" log --since="${sinced}" --pretty=format:"%H"); do
  cid=$(git -C "${dir}" show "${rev}" --no-patch --format="%s%n%n%b" | sed -nre 's!Change-Id: (.*$)!\1!p')
  vuser=$(curl -s -X GET --user "${user}:${passwd}" "${url}~${br}~${cid}/detail" | tail -n +2 | jq .labels.Verified.approved.username)
  if [ "${funcuser}" != "${vuser}" ]; then
    git -C "${dir}" show "${rev}" --no-patch --format="%ad%n%snb" | head
    echo "~~~~ ${rev}: ${cid}: ${vuser}"
    echo ""
  fi
done
