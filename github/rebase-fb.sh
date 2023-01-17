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

action() {
echo -e "\033[1;36m[Action]:\033[0m $1"
}
###

[ -z "${FB_NAME}" ] && exit 1
info "Parsing FB ${FB_NAME} Seed Job Configuration..."
export FILTER_BRANCH_SQUELCH_WARNING=1 #filter-branch hide warnings
current_date=$(date '+%s')
action "Parsing FB repositories from catalog..."
fblist=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_$(echo ${FB_NAME//-} | tr '[:upper:]' '[:lower:]').groovy" | grep "project:")
modules_length=$(echo $fblist | grep -o 'project:' | wc -w)
info "Modules count: ${modules_length}"
counter=0
action "Done. Performing action..."
while IFS=']' read -r line; do
    counter=$((counter+1))  
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    if [ -z "${BASE_BRANCH:-}" ]; then 
      if [ "${org,,}" = "meeds-io" ] && [[ ! $item =~ .*-parent-pom ]] && [[ ! $item =~ ^deeds ]]; then 
        baseBranch=develop-exo
      else 
        baseBranch=develop
      fi
    elif [[ $item =~ ^deeds ]]; then 
      baseBranch=develop
    else
      baseBranch="${BASE_BRANCH}"
    fi
    [ "${org,,}" = "meeds-io" ] || baseBranch="develop"
    action "(${counter}/${modules_length}) -- Checking divergence status between ${baseBranch} and feature/${FB_NAME} on repository: ${org}/${item}..."
    status=$(gh api /repos/${org}/${item}/compare/${baseBranch}...feature/${FB_NAME} | jq .status | xargs -r echo)
    if [ "${status:-}" != "diverged" ]; then
      info "Not diverged -> Skipped!"
      continue
    fi
    info "Divergence detected!"
    action "Starting rebase..."
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
    upstream=$(git log --oneline origin/${baseBranch}..origin/feature/${FB_NAME} | wc -l)
    downstream=$(git log --oneline origin/feature/${FB_NAME}..origin/${baseBranch} | wc -l)
    [ "$downstream" -gt "0" ] && downStreamMsg="\033[1;31m${downstream}\033[0m" || downStreamMsg="\033[1;34m${downstream}\033[0m" # if downstream > 1 color red else color blue
    echo "================================================================================================="
    echo -e " Module (${counter}/${modules_length}): ${org}/${item} -- Base Branch: ${baseBranch} -- Diff: ^ \033[1;34m${upstream}\033[0m, v ${downStreamMsg}"
    echo "================================================================================================="
    git checkout feature/${FB_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)
    if ! git rebase origin/${baseBranch} feature/${FB_NAME} >/dev/null; then
      info "Rebasing with recursive strategy has failed!"
      action "Trying ours rebase strategy without detecting changes loss (helpful for detecting and removing backported commits)..."
      git rebase --abort || :
      if ! git rebase origin/${baseBranch} feature/${FB_NAME} --strategy-option ours >/dev/null || [ ! -z "$(git diff -w origin/feature/${FB_NAME})" ]; then 
        error "Could not rebase feature/${FB_NAME}!"
        exit 1
      fi
    fi
    git log --oneline --cherry origin/${baseBranch}..HEAD
    if [ ! -z "$(git diff origin/feature/${FB_NAME} 2>/dev/null)" ]; then
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
    popd &>/dev/null
done <<< "$fblist"
echo "================================================================================================="
success "Rebase done!"
