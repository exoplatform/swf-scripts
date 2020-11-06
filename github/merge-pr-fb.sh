#!/bin/bash -eu
# Args:
# FB_NAME: Mandatory -> Feature Branch name ( without feature/)
# Reviewers: Optional -> List of Github reviewers's ids (Separated with comma ,) Ex: abc,def,ghi,jkl

echo "Parsing FB ${FB_NAME} Seed Job Configuration..."

[ -z "${FB_NAME}" ] && exit 1

# Check gh command is installed
hash gh 2>/dev/null

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_${FB_NAME}.groovy" --output fblist.txt
cat fblist.txt | grep "project:" >fblistfiltred.txt

echo "Done. Performing action..."
current_dir=$PWD
while IFS= read -r line; do
    cd $current_dir &>/dev/null
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]" | xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    prs_list=($(gh pr status -R ${org}/${item} | sed -n '/Created/,/Requesting/p' | grep "#" | awk '{print $1}' | sed 's/#//g' | xargs))
    [ -z "${prs_list[@]:-}" ] && echo "No Pull Requests on ${org}/${item} repository! Skipping..." && continue
    git clone git@github.com:${org}/$item
    pushd $item &>/dev/null
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    [ -z "${default_branch}" ] && continue
    for pr in "${prs_list[@]}"; do
        echo "Checking PR https://github.com/${org}/${item}/pull/${pr}..."
        gh pr checkout -R ${org}/${item} ${pr} &>/dev/null
        #gh pr checks ${pr} -R ${org}/${item} &>/dev/null || continue
        [[ "$(git rev-parse --abbrev-ref HEAD)" =~ ^tmp-[0-9]+$ ]] || continue
        echo "Upadating PR #${pr} if needed..."
        git merge ${default_branch} --no-edit
        git push -u origin $(git rev-parse --abbrev-ref HEAD) --quiet
        if [ "$(git diff --name-only origin/$default_branch | wc -l)" -eq "0" ]; then
            echo "There is no commit to merge ! Closing this PR!"
            git push --delete origin $(git rev-parse --abbrev-ref HEAD)
            continue
        fi
        if gh pr checks ${pr} -R ${org}/${item} &>/dev/null && gh pr view ${pr} -R ${org}/${item} 2>&1 | grep reviewers | grep Approved; then
            gh pr merge ${pr} -R ${org}/${item} --rebase --delete-branch
            echo "OK! PR https://github.com/${org}/${item}/pull/${pr} is merged!"
        fi
    done
    popd &>/dev/null
done <fblistfiltred.txt
