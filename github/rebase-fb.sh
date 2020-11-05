#!/bin/bash -eu


echo "Parsing FB ${FB_NAME} Seed Job Configuration..."

[ -z "${FB_NAME}" ] && exit 1

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
rm -f /tmp/prlist.txt &>/dev/null
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_${FB_NAME}.groovy" --output fblist.txt
cat fblist.txt | grep "project:" > fblistfiltred.txt

echo "Done. Performing action..."
while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    echo "Rebasing ${org}/${item}:feature/${FB_NAME}..."
    git clone git@github.com:${org}/$item
    pushd $item &>/dev/null
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    [ -z "${default_branch}" ] && continue
    git checkout feature/${FB_NAME} 
    git rebase origin/$default_branch feature/${FB_NAME}
    git log --oneline --cherry origin/$default_branch..HEAD
    git push origin feature/${FB_NAME} --force-with-lease
    popd &>/dev/null
done < fblistfiltred.txt
