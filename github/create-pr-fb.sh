#!/bin/bash -eu
# Args:
# FB_NAME: Mandatory -> Feature Branch name ( without feature/)
# Reviewers: Optional -> List of Github reviewers's ids (Separated with comma ,) Ex: abc,def,ghi,jkl

echo "Parsing FB ${FB_NAME} Seed Job Configuration..."

[ -z "${FB_NAME}" ] && exit 1

set +u
[ -z "${REVIEWERS}" ] && REVIEWERS=""
[ -z "${MODULES}" ] && MODULES=""
set -u

# Check gh command is installed
hash gh 2>/dev/null

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_${FB_NAME}.groovy" --output fblist.txt
cat fblist.txt | grep "project:" >fblistfiltred.txt

echo "Done. Performing action..."

while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]" | xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    [ ! -z "${MODULES}" ] && [[ ! "$(echo ${MODULES} | sed 's/,/ /g')" =~ "${item}" ]] && continue
    echo "Rebasing ${org}/${item}:feature/${FB_NAME}..."
    git clone git@github.com:${org}/$item
    pushd $item &>/dev/null
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    [ -z "${default_branch}" ] && continue
    git checkout feature/${FB_NAME}
    git rebase origin/$default_branch feature/${FB_NAME}
    git log --oneline --cherry origin/$default_branch..HEAD
    if [ "$(git log --oneline --cherry origin/$default_branch..HEAD | wc -l)" -lt "2" ]; then
        echo "There is no commit to merge ! Skipping this repository!"
        continue
    fi
    branch_name="tmp-$(date +'%s')"
    git checkout -b $branch_name
    # Getting maven dependencies changes commit id
    base_commit=$(git rev-parse $default_branch)
    maven_dep_commit_id=$(git rev-list ${base_commit}..HEAD --oneline | tail -1 | cut -d " " -f 1)
    [ -z "${maven_dep_commit_id}" ] && continue
    echo "Rebasing $branch_name with ${default_branch} and removing the following commit"
    git log --oneline --cherry $default_branch..$maven_dep_commit_id
    git rebase --onto $base_commit $maven_dep_commit_id $branch_name
    git push -u origin $branch_name &>/dev/null
    gh pr create --title "Feature/${FB_NAME}: Weekly PR #$(date +%V)" --body "Weekly ${FB_NAME} Pull Request" --base "${default_branch}" --reviewer "${REVIEWERS}" -R "${org}/${item}" -H ${branch_name}
    gh pr merge -R "${org}/${item}" --auto --rebase
    popd &>/dev/null
done <fblistfiltred.txt
