#!/bin/bash -eu 
set -o pipefail 
PR_JSON=""
getJsonItem() {
    echo $PR_JSON | jq -r ".$1"
}

getPRReviewers() {
    echo $PR_JSON | jq -r '[ .requested_reviewers[].login ] | join(",")'
}

# Sanitize PR URL
PR_URL=$(echo ${PR_URL:-} | grep -oP 'https://github.com/[a-zA-Z0-9-_]+/[a-zA-Z0-9-_]+/pull/[0-9]+')
if [ -z "${PR_URL:-}"]; then 
  echo "Error: Please provide a valid PR URL!"
  exit 1
fi

if [ -z "${TARGET_BASE_BRANCH:-}" ]; then 
  echo "Error: Please provide a valid target base branch!"
  exit 1
fi

echo "Analyzing the supplied PR..."
PR_API_URI=$(echo ${PR_URL} | sed  -e 's|https://github.com|/repos|g' -e 's|/pull/|/pulls/|g' )
PR_CLONE_URL=$(echo ${PR_URL} | sed  -e 's|https://github.com/|git@github.com:|g' -Ee 's|/pull/.*|.git|g' )
echo $PR_API_URI $PR_CLONE_URL
PR_JSON=$(gh api ${PR_API_URI})
echo "Checking PR merge status..."
PR_MERGED=$(getJsonItem merged)

if ! ${PR_MERGED:-false}; then 
  echo "Error: You should pick a merged PR!"
  exit 1
fi
echo "OK PR is merged."
echo "Checking PR merge commit"
PR_MERGE_COMMIT=$(getJsonItem merge_commit_sha)
echo "OK PR merge commit is ${PR_MERGE_COMMIT}"
PR_TITLE=$(getJsonItem title)
PR_BODY=$(getJsonItem body)
PR_OWNER=$(getJsonItem user.login)
PR_REVIEWERS=$(getPRReviewers)
PR_REPO=$(getJsonItem head.repo.name)
git clone $PR_CLONE_URL &>/dev/null
pushd ${PR_REPO}
git checkout ${TARGET_BASE_BRANCH} &>/dev/null
BRANCH_NAME=backport_$(date +%s)
git checkout -b ${BRANCH_NAME}
if ! git cherry-pick -x ${PR_MERGE_COMMIT}; then 
    git cherry-pick --abort &>/dev/null || true
    echo "Cherry-pick failed! Performing patch method..."
    PR_PATCH_URL=$(getJsonItem patch_url)
    wget $PR_PATCH_URL -O ../patch.diff &>/dev/null 
    git apply ../patch.diff
    commitFile=$(mktemp)
    echo ${PR_TITLE} > $commitFile
    echo >> $commitFile
    echo ${PR_BODY} > $commitFile 
    echo >> $commitFile
    echo "(Cherry-picked from ${PR_MERGE_COMMIT})" > $commitFile 
    rm ../patch.diff
    git add . # not recommended
    git commit -F $commitFile 
    rm $commitFile 
fi
git push origin HEAD
if [ ${REVIEWERS:-} = "_OWNER_" ]; then 
    REVIEWERS=$PR_OWNER
fi
if [ ${REVIEWERS:-} = "_REVIEWERS_" ]; then
    if [ -z "${PR_REVIEWERS:-}" ]; then 
      echo "Error: This PR does not have reviewers! Please select other reviewers. Abort"
      exit 1
    else  
      REVIEWERS=$PR_REVIEWERS
    fi
fi
if [ ! -z ${GH_ACTOR_TOKEN:-} ]; then
  export GH_TOKEN=${GH_ACTOR_TOKEN}
fi
echo "OK! Creating backport PR with base branch ${TARGET_BASE_BRANCH}, assignee ${PR_OWNER}, and reviewers ${REVIEWERS}..."
gh pr create --repo $PR_CLONE_URL -f --reviewer "${REVIEWERS}" --assignee "${PR_OWNER}" --base "${TARGET_BASE_BRANCH}" --head ${BRANCH_NAME}
echo "Done."
if [ "${AUTO_MERGE:-DEFAULT}" != "DEFAULT" ]; then 
  echo "Enabling ${AUTO_MERGE:-DEFAULT} auto merge..."
  gh pr merge --auto --${AUTO_MERGE} --repo $PR_CLONE_URL
  echo "Done."
fi