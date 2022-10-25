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
export DEFAULT_CP_DAYS_BEFORE=3 # default cherry-picks checkpoint in days in case of absence of tag

isAlreadyBackported() {
  local ref="$2"
  local TARGET_COMMIT_PATCHID=$(
    git show --patch-with-raw "$1" |
	  git patch-id |
	  cut -d' ' -f1
  )

  local MATCHING_COMMIT_SHA=""
  for c in $(git rev-list origin/$ref ); do
	  if [[ $(git show --patch-with-raw "$c" | git patch-id | cut -d' ' -f1) == "${TARGET_COMMIT_PATCHID}" ]]; then 
      MATCHING_COMMIT_SHA=$c 
	    break; 
	  fi
  done
  [ ! -z "$MATCHING_COMMIT_SHA" ]
}

seedfileraw=$(mktemp)
seedfilefiltred=$(mktemp)

current_date=$(date '+%s')
echo "Parsing Modules repositories from catalog..."
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/platform/seed_jobs_ci.groovy" --output ${seedfilefiltred}
cat ${seedfilefiltred} | grep "${DIST_BRANCH}" | grep "project:" > ${seedfileraw}
modules_length=$(wc -l ${seedfileraw} | awk '{ print $1 }')
counter=1
echo "Done. Performing action..."
ret=0
baseDir=$PWD
while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    echo "================================================================================================="
    echo -e " Module (${counter}/${modules_length}): \e]8;;http://github.com/${org}/${item}\a${org}/${item}\e]8;;\a"
    echo "================================================================================================="
    cd $baseDir
    git init $item &>/dev/null
    cd $item &>/dev/null
    git remote add origin git@github.com:${org}/${item}.git &>/dev/null
    git fetch origin develop ${DIST_BRANCH} --tags &>/dev/null
    checkpointTag="@cp-${DIST_BRANCH}"
    if ! git rev-parse ${checkpointTag} 2>/dev/null; then
      tag_commit=$(git log --no-merges --pretty=format:"%H" --since="${DEFAULT_CP_DAYS_BEFORE}days" | tail -1)
      git tag ${checkpointTag} ${tag_commit}
    fi 
    messageCP=$(git show --pretty=format:%s -s ${checkpointTag} )
    info "Cherry-pick checkpoint is at: ($(git rev-parse --short ${checkpointTag})) $messageCP."
    prev_head=$(git rev-parse --short origin/$DIST_BRANCH)
    # Applying cherry-picks 
    commitIds=$(git log --no-merges --pretty=format:"%H" ${checkpointTag}..origin/develop --reverse | xargs)
    if [ -z "${commitIds:-}" ]; then 
      info "Nothing to backport!"
      git push origin ${checkpointTag} -f &>/dev/null
      continue
    fi
    echo "Start backporting..."
    cherryPickFailed=false
    for commitId in $commitIds; do
      message=$(git show --pretty=format:%s -s $commitId )
      body=$(git show --pretty=format:%b -s $commitId )
      if [[ "${body:-}" =~ "#dontcp" ]]; then 
        info "Skipped marked commit: ($(git rev-parse --short $commitId)) $message!"
        continue 
      fi
      if isAlreadyBackported $commitId $DIST_BRANCH; then 
        info "Skipped already backported commit: ($(git rev-parse --short $commitId)) $message!"
        continue 
      fi
      info "Cherry-picking commit: ($(git rev-parse --short $commitId)) $message..."
      if ! git cherry-pick -x $commitId; then 
        ret=1
        error "Cherry-pick failed! Please fix it manually and update tag: ${checkpointTag} on the source commit: $commitId of develop branch, then relaunch this job!"
        cherryPickFailed=true
        break
      fi
    done 
    if $cherryPickFailed; then 
      error "Failed to backport commits for ${org}/${item}!"
      continue
    fi
    if [ ! -z "$(git diff origin/${DIST_BRANCH} 2>/dev/null)" ]; then
      info "Reseting commits authors..."
      git filter-branch --commit-filter 'export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"; export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"; git commit-tree "$@"' -- origin/$DIST_BRANCH..HEAD
      info "Changes to be pushed:"
      echo -e "\033[1;32m****\033[0m"
      git log origin/${DIST_BRANCH}..HEAD --oneline --pretty=format:"(%C(yellow)%h%Creset) %s" 
      echo -e "\n\033[1;32m****\033[0m"
    else 
      info "No changes detected!"  
    fi
    new_head=$(git rev-parse --short HEAD)
    if [ "${prev_head}" != "${new_head}" ]; then
      info "Previous $DIST_BRANCH HEAD: \033[1;31m${prev_head}\033[0m, New $DIST_BRANCH HEAD: \033[1;32m${new_head}\033[0m."
      git push origin HEAD:${DIST_BRANCH} | grep -v remote ||:
    fi
    info "Previous CP Checkpoint HEAD: \033[1;31m$(git rev-parse --short ${checkpointTag})\033[0m, New CP Checkpoint HEAD: \033[1;32m$(git rev-parse --short origin/develop)\033[0m."
    git tag ${checkpointTag} origin/develop -f 
    git push origin ${checkpointTag} -f   
done < ${seedfileraw}
echo "Cleaning up temporary files..."
rm -v ${seedfileraw}
rm -v ${seedfilefiltred}
echo "================================================================================================="
if [ $ret -eq "0" ]; then
  success "Backporting done!"
else 
  error "Some Backports have failed!"
fi
exit $ret