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
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/platform/seed_jobs_ci.groovy" --output ${seedfilefiltred}
cat ${seedfilefiltred} | grep "${DIST_BRANCH}" | grep "project:" > ${seedfileraw}
modules_length=$(wc -l ${seedfileraw} | awk '{ print $1 }')
counter=0
echo "Done. Performing action..."
ret=0
while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    counter=$((counter+1))
    echo "================================================================================================="
    echo -e " Module (${counter}/${modules_length}): \e]8;;http://github.com/${org}/${item}\a${org}/${item}\e]8;;\a"
    echo "================================================================================================="
    git init $item &>/dev/null
    pushd $item &>/dev/null
    git remote add origin git@github.com:${org}/${item}.git &>/dev/null
    git fetch origin develop ${DIST_BRANCH} &>/dev/null
    git checkout develop >/dev/null
    prev_head=$(git rev-parse --short origin/$DIST_BRANCH)
    # Rebase local develop branch on target dist develop as preparation for FF merge (linear history)
    if ! git rebase origin/$DIST_BRANCH develop &>/dev/null; then
      git rebase --abort &>/dev/null
      git checkout $DIST_BRANCH -f
      git merge origin/develop --no-commit -X ours
      git commit -m "Merge develop into $DIST_BRANCH"
      if [ -z "$(git diff -w origin/$DIST_BRANCH)" ]; then 
        git push origin $DIST_BRANCH
        continue
      fi
      ret=1
      echo ""
      echo "==========================================================="
      error "Fatal! Failed to perform reverse rebase! please fix it manually!"
      echo "Hint:"
      echo "  git fetch"
      echo "  git checkout develop && git reset --hard origin/develop"
      echo "  git checkout -b fixrebase$(date '+%s')"
      echo "  git rebase origin/$DIST_BRANCH"
      echo ">>Fix conflicts and continue rebasing by using command: "
      echo "  git rebase --continue"
      echo ">>Push to remote repository"
      echo "  git push origin HEAD"
      echo ">>Create Pull Request to $DIST_BRANCH (or push directly for admins)"
      echo ">>Once approved, do not squash nor rebase & merge !! Perform a Fast forward Merge"
      echo "  git push origin HEAD:$DIST_BRANCH"
      echo ">>Re-perform the reverse rebase to check reverse rebase health status"
      echo ">> -- Otherwise, a merge commit would be necessary to prevent repeating re-cherry-picking commit and submit an new merge-base"
      echo "  git merge origin/develop"
      echo ">> -- Then, create a pull request to $DIST_BRANCH branch or push directly for admins"
      echo "==========================================================="
      echo ""
      popd &>/dev/null
      continue
    fi
    if [ ! -z "$(git diff origin/${DIST_BRANCH} 2>/dev/null)" ]; then
      info "Changes to be pushed:"
      echo -e "\033[1;32m****\033[0m"
      git log origin/${DIST_BRANCH}..HEAD --oneline --pretty=format:"(%C(yellow)%h%Creset) %s" 
      echo -e "\n\033[1;32m****\033[0m"
    else 
      info "No changes detected!"  
    fi
    new_head=$(git rev-parse --short HEAD)
    if [ "${prev_head}" != "${new_head}" ]; then
      info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
      git push origin HEAD:${DIST_BRANCH} | grep -v remote ||:
    fi
    popd &>/dev/null
done < ${seedfileraw}
echo "Cleaning up temorary files..."
rm -v ${seedfileraw}
rm -v ${seedfilefiltred}
echo "================================================================================================="
if [ $ret -eq "0" ]; then
  success "Reverse Rebase done!"
else 
  error "Some rebase have failed!"
fi
exit $ret