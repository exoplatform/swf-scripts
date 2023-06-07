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

seedfileraw=$(mktemp)
seedfilefiltred=$(mktemp)

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/platform/seed_jobs_meeds_meed.groovy" --output ${seedfilefiltred}
cat ${seedfilefiltred} | grep "project:" > ${seedfileraw}
modules_length=$(wc -l ${seedfileraw} | awk '{ print $1 }')
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
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
   
    baseBranch=develop

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
    ((counter++))  
    popd &>/dev/null
done < ${seedfileraw}
echo "Cleaning up temorary files..."
rm -v ${seedfileraw}
rm -v ${seedfilefiltred}
echo "================================================================================================="
success "Rebase done!"