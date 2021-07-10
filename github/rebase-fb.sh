#!/bin/bash -eu

### Colors
info() {
echo "\033[1;33m[Info]    \033[0m $1"
}

error() {
echo "\033[1;31m[Error]   \033[0m $1"
}

success() {
echo "\033[1;32m[Success] \033[0m $1"
}
###

[ -z "${FB_NAME}" ] && exit 1
info "Parsing FB ${FB_NAME} Seed Job Configuration..."

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
rm -f /tmp/prlist.txt &>/dev/null
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_$(echo ${FB_NAME//-} | tr '[:upper:]' '[:lower:]').groovy" --output fblist.txt
cat fblist.txt | grep "project:" > fblistfiltred.txt

echo "Done. Performing action..."
while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    echo "================================================================================================="
    echo " Module: ${org}/${item}"
    echo "================================================================================================="
    git init $item &>/dev/null
    pushd $item &>/dev/null
    git remote add -t develop -t feature/${FB_NAME} origin git@github.com:${org}/${item}.git &>/dev/null
    default_branch=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
    git fetch &>/dev/null
    default_branch="develop"
    git checkout feature/${FB_NAME} &>/dev/null
    if ! git rebase --exit-code origin/$default_branch feature/${FB_NAME}; then 
      error "Could not rebase feature/${FB_NAME}!"
      exit 1
    fi
    git log --oneline --cherry origin/$default_branch..HEAD
    if [ "$(git log HEAD..FETCH_HEAD --oneline 2>/dev/null | wc -l)" -gt "0" ]; then
      info "Changes before the rebase:"
      git log HEAD..FETCH_HEAD --oneline --format="(%h) %s"
      git push origin feature/${FB_NAME} --force-with-lease | grep -v remote ||:
    else 
      info "No changes detected!"  
    fi
    popd &>/dev/null
done < fblistfiltred.txt
success "Rebase done!"