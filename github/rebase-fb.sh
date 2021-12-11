#!/bin/bash -eu

### Colors
info() {
echo -e "\033[1;34m[Info]\033[0m $1"
}

error() {
echo -e "\033[1;31m[Error]\033[0m $1"
}

success() {
echo -e "\033[1;32m[Success]\033[0m $1"
}
###

[ -z "${FB_NAME}" ] && exit 1
info "Parsing FB ${FB_NAME} Seed Job Configuration..."
export FILTER_BRANCH_SQUELCH_WARNING=1 #filter-branch hide warnings
current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
rm -f /tmp/prlist.txt &>/dev/null
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_$(echo ${FB_NAME//-} | tr '[:upper:]' '[:lower:]').groovy" --output fblist.txt
cat fblist.txt | grep "project:" > fblistfiltred.txt
modules_length=$(wc -l fblistfiltred.txt | awk '{ print $1 }')
counter=1
echo "Done. Performing action..."
while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    echo "================================================================================================="
    echo -e " Module (${counter}/${modules_length}): \e]8;;http://github.com/${org}/${item}\a${org}/${item}\e]8;;\a"
    echo "================================================================================================="
    git init $item &>/dev/null
    pushd $item &>/dev/null
    git remote add -t develop -t feature/${FB_NAME} origin git@github.com:${org}/${item}.git &>/dev/null
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    git fetch &>/dev/null
    default_branch="develop"
    git checkout feature/${FB_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)
    if ! git rebase origin/$default_branch feature/${FB_NAME} >/dev/null; then 
      info "Recursive rebase strategy failed! Trying OURS rebase strategy without changes loss..."
      git rebase --abort || :
      if ! git rebase origin/$default_branch feature/${FB_NAME} --strategy-option ours >/dev/null || [ ! -z "$(git diff -w origin/feature/${FB_NAME})" ]; then 
        error "Could not rebase feature/${FB_NAME}!"
        exit 1
      fi
    fi
    git log --oneline --cherry origin/$default_branch..HEAD
    if [ ! -z "$(git diff origin/feature/${FB_NAME} 2>/dev/null)" ]; then
      info "Reseting commits authors..."
      git filter-branch --commit-filter 'export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"; export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"; git commit-tree "$@"' -- origin/$default_branch..HEAD
      info "Changes before the rebase:"
      echo -e "\033[1;32m****\033[0m"
      git log HEAD..origin/feature/${FB_NAME} --oneline --pretty=format:"(%C(yellow)%h%Creset) %s"
      echo -e "\033[1;32m****\033[0m"
    else 
      info "No changes detected!"  
    fi
    new_head=$(git rev-parse --short HEAD)
    if [ "${prev_head}" != "${new_head}" ]; then
      info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
      git push origin feature/${FB_NAME} --force-with-lease | grep -v remote ||:
    fi
    ((counter++))  
    popd &>/dev/null
done < fblistfiltred.txt
echo "================================================================================================="
success "Rebase done!"