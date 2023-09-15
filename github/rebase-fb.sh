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

warn() {
echo -e "\033[1;33m[Warning]\033[0m $1"
}

action() {
echo -e "\033[1;36m[Action]:\033[0m $1"
}
###
[ -z "${FB_NAME}" ] && exit 1
set +u
[ -z "${REBASE_PRS}" ] && REBASE_PRS=false
set -u
info "Parsing FB ${FB_NAME} Seed Job Configuration..."
export FILTER_BRANCH_SQUELCH_WARNING=1 #filter-branch hide warnings
current_date=$(date '+%s')
action "Parsing FB repositories from catalog..."
fblist=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_$(echo ${FB_NAME//-} | tr '[:upper:]' '[:lower:]').groovy" | grep "project:")
if ${COMPANY_MODULES_ENABLED:-false}; then 
  cmpfblist=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/company/seed_jobs_ci.groovy" | grep "feature/${FB_NAME}" | grep "project:")
  fblist=$(echo -e "${fblist}\n${cmpfblist}")
fi

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
    action "(${counter}/${modules_length}) -- ${org}/${item}: Checking ${baseBranch}...feature/${FB_NAME} status..."
    compareJson=$(gh api /repos/${org}/${item}/compare/${baseBranch}...feature/${FB_NAME})
    status=$(echo "$compareJson" | jq -r .status)
    aheadby=$(echo "$compareJson" | jq -r .ahead_by)
    behindby=$(echo "$compareJson" | jq -r .behind_by)
    info "Status: $status - Ahead by: $aheadby - Behind by $behindby."
    if [ "${status:-}" != "diverged" ]; then
      continue
    fi
    action "Starting rebase..."
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
    git checkout feature/${FB_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)
    if ! git -c advice.skippedCherryPicks=false rebase origin/${baseBranch} feature/${FB_NAME} >/dev/null; then
      info "Rebasing with recursive strategy has failed!"
      action "Trying ours rebase strategy without detecting changes loss (helpful for detecting and removing backported commits)..."
      git rebase --abort || :
      if ! git -c advice.skippedCherryPicks=false rebase origin/${baseBranch} feature/${FB_NAME} --strategy-option ours >/dev/null || [ ! -z "$(git diff -w origin/feature/${FB_NAME})" ]; then 
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
      git push origin feature/${FB_NAME} --force-with-lease 2>&1 | grep -v remote ||:
      # Looking for incorrect submodules version
      wrongSubmodulesVersion=$(grep -irl '<version>.*\.x-SNAPSHOT</version>' --include=pom.xml | xargs)
      if [ ! -z ${wrongSubmodulesVersion} ]; then
        warn "Unfixed ${FB_NAME} FB maven submodules version detected (x-SNAPSHOT instead of x-${FB_NAME}-SNAPSHOT)! Please fix their pom.xml files"
        printf " - %s\n" $wrongSubmodulesVersion
      fi
      if ${REBASE_PRS}; then 
        action "Looking for PRs with base feature/${FB_NAME}..."
        fbPRs=$(gh api /repos/${org}/${item}/pulls?base=feature/${FB_NAME})
        for fbPR in $(echo "${fbPRs}" | jq -r '.[] | @base64'); do
          _jq() {
            echo ${fbPR} | base64 --decode | jq -r ${1}
          }
          prBranch=$(_jq '.head.ref')
          prNumber=$(_jq '.number')
          action "Trying to rebase https://github.com/${org}/${item}/pull/${prNumber} branch: ${prBranch}..."
          git checkout -f ${prBranch} &>/dev/null
          prev_head=$(git rev-parse --short HEAD)
          if ! git rebase feature/${FB_NAME} ${prBranch} >/dev/null; then 
            error "Cannot rebase ${prBranch} on feature/${FB_NAME} for ${org}/${item}! Skipped!"
            git rebase --abort &>/dev/null || :
          else
            new_head=$(git rev-parse --short HEAD)
            info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
            git push origin ${prBranch}:${prBranch} --force-with-lease 2>&1 | grep -v remote ||:
          fi
        done
        info "PRs rebase finished."
      fi
    fi
    popd &>/dev/null
done <<< "$fblist"
echo "================================================================================================="
success "Rebase done!"
