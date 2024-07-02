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

export FILTER_BRANCH_SQUELCH_WARNING=1 #filter-branch hide warnings
export DEFAULT_ORG="Meeds-io"

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
modulesList=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/platform/seed_jobs_meeds_meed.groovy" | grep "project:")
modules_length=$(echo $modulesList | grep -o 'project:' | wc -w)
counter=0
echo "Done. Performing action..."

while IFS=']' read -r line; do
    counter=$((counter+1))  
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && org=${DEFAULT_ORG}
    echo "================================================================================================="
    echo -e " Module (${counter}/${modules_length}): \e]8;;http://github.com/${org}/${item}\a${org}/${item}\e]8;;\a"
    echo "================================================================================================="
    baseBranch=develop
    compareJson=$(gh api /repos/${org}/${item}/compare/${baseBranch}...${BRANCH_NAME})
    status=$(echo "$compareJson" | jq -r .status)
    aheadby=$(echo "$compareJson" | jq -r .ahead_by)
    behindby=$(echo "$compareJson" | jq -r .behind_by)
    info "Status: $status - Ahead by: $aheadby - Behind by $behindby."
    if [ "${status:-}" != "diverged" ]; then
      continue
    fi
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
   
    git checkout ${BRANCH_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)
    if ! git rebase origin/${baseBranch} ${BRANCH_NAME} >/dev/null; then
      info "Rebase with recursive strategy has failed! Trying ours rebase strategy without detecting changes loss (helpful for detecting and removing backported commits)..."
      git rebase --abort || :
      if ! git rebase origin/${baseBranch} ${BRANCH_NAME} --strategy-option ours >/dev/null || [ ! -z "$(git diff -w origin/${BRANCH_NAME})" ]; then 
        error "Could not rebase ${BRANCH_NAME}!"
        exit 1
      fi
    fi
    git log --oneline --cherry origin/${baseBranch}..HEAD
    if [ ! -z "$(git diff origin/${BRANCH_NAME} 2>/dev/null)" ]; then
      info "Reseting commits authors..."
      git filter-branch --commit-filter 'export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"; export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"; git commit-tree "$@"' -- origin/${baseBranch}..HEAD
      info "Changes before the rebase:"
      echo -e "\033[1;32m****\033[0m"
      git log HEAD..origin/${BRANCH_NAME} --oneline --pretty=format:"(%C(yellow)%h%Creset) %s"
      echo -e "\033[1;32m****\033[0m"
    else 
      info "No changes detected!"  
    fi
    new_head=$(git rev-parse --short HEAD)
    if [ "${prev_head}" != "${new_head}" ]; then
      info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
      git push origin ${BRANCH_NAME} --force-with-lease | grep -v remote ||:
    fi
    popd &>/dev/null
done <<< "$modulesList"
echo "================================================================================================="
success "Rebase done!"