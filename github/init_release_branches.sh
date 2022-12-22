#!/bin/bash -eu 

# Prerequisities:
# GIT_TOKEN: A valid Github token to fetch continuous release modules
# RELEASE_SUFFIX: Jenkins Param: Continuous release tag suffix (Ex 20210621)
# MILESTONE_SUFFIX: Jenkins Param: Target milestone release suffix (Ex M25,RC01)
# TASK_ID: Tribe's task id (only digits)

echo "Parsing CI CD Release modules..."

current_date=$(date '+%s')
modules=$(curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/continuous-release-template-exo.json" )

[ -z "${TARGET_BRANCH:-}" ] && TARGET_BRANCH="milestone_release"

echo "Done. Performing action..."
for module in $(echo "${modules}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${module} | base64 --decode | jq -r ${1}
    }
    name=$(_jq '.name')
    git_organization=$(_jq '.git_organization')
    version=$(_jq '.release.version')
    [ -z "${name}" ] && continue
    [ -z "${git_organization}" ] && continue
    [ "${name}" = "community-website" ] && continue
    [ "${name}" = "platform-qa-tribe" ] && continue
    # Module to be not released -> Skipped
    [[ "${version}" =~ .*-\$\{release-version\}$ ]] || continue
    git clone git@github.com:${git_organization}/$name
    pushd $name &>/dev/null
    module_version=$(echo $version | sed "s/\${release-version}/${RELEASE_SUFFIX}/g")
    milestone_version=$(echo $version | sed "s/\${release-version}/${MILESTONE_SUFFIX}/g")
    git checkout -b ${TARGET_BRANCH} ${module_version}
    commitsSWFCount="$(git log --grep '\[exo-release\]' HEAD~2..HEAD --oneline | wc -l)" # HEAD~2..HEAD: Max two commits checks to expand if needed
    # Revert SWF Release commits
    if [ "${commitsSWFCount}" = "2" ]; then 
        git revert HEAD HEAD^ --no-commit # Revert two commits
    elif [ "${commitsSWFCount}" = "1" ]; then 
        git revert HEAD --no-commit # Revert one commit
    else 
        echo "Error! Unmanaged commits number ${commitsSWFCount}! Abort"
        exit 1
    fi
    git commit -m "TASK-${TASK_ID}: Prepare Release ${milestone_version} based on ${module_version}"
    git push origin ${TARGET_BRANCH} --force
    popd &>/dev/null
done
