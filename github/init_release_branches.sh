#!/bin/bash -eu 

# Prerequisities:
# GIT_TOKEN: A valid Github token to fetch continuous release modules
# RELEASE_SUFFIX: Jenkins Param: Continuous release tag suffix (Ex 20210621)
# MILESTONE_SUFFIX: Jenkins Param: Target milestone release suffix (Ex M25,RC01)
# TASK_ID: Tribe's task id (only digits)

echo "Parsing CI CD Release modules..."
FETCH_DEPTH_MAX=3
# Does not correlate with FETCH DEPTH! 2 commits (1-Update module version, 2- Update dependencies snapshot to released version)
# Always SWF_RELEASE_COMMITS_MAX should be lower than FETCH_DEPTH_MAX
SWF_RELEASE_COMMITS_MAX=2
if ((SWF_RELEASE_COMMITS_MAX >= FETCH_DEPTH_MAX)); then 
    echo "Error! ${SWF_RELEASE_COMMITS_MAX} should be lower than ${FETCH_DEPTH_MAX}"
    exit 1
fi
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
    module_version=$(echo $version | sed "s/\${release-version}/${RELEASE_SUFFIX}/g")
    if [ ! -z "${MILESTONE_SUFFIX:-}" ]; then 
        milestone_version=$(echo $version | sed "s/\${release-version}/${MILESTONE_SUFFIX}/g")
    else 
        milestone_version=$(echo $version | sed "s/-\${release-version}//g")
    fi
    git clone --depth ${FETCH_DEPTH_MAX} --branch ${module_version} git@github.com:${git_organization}/$name
    pushd $name &>/dev/null
    git checkout -b ${TARGET_BRANCH} ${module_version}
    commitsSWFCount="$(git log --grep '\[exo-release\]' HEAD~${SWF_RELEASE_COMMITS_MAX}..HEAD --oneline | wc -l)" # HEAD~2..HEAD: Max two commits checks to expand if needed
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
