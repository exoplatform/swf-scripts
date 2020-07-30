#!/bin/bash

# Requirement:
# GIT_TOKEN: ENV VAR: GIT API TOKEN
# PR_URL: PARAMETER (STRING): PULL Request URL
# TARGET_BRANCH: : PARAMETER (STRING): Target Branch : Example (stable/6.0.x)
if [ -z "${GIT_TOKEN}" ]; then
  echo "Error: GIT_TOKEN is not specified!"
  exit 1
fi

if [ -z "${PR_URL}" ]; then
  echo "Error: Parameter PR_URL is not specified!"
  exit 1
fi

if [ -z "${TARGET_BRANCH}" ]; then
  echo "Error: Parameter TARGET_BRANCH is not specified!"
  exit 1
fi

if [ -z "${TARGET_ORGANIZATION}" ]; then
  echo "Error: Parameter TARGET_ORGANIZATION is not specified!"
  exit 1
fi

PR_URL=$(sed -E 's|/files$||g' <<<${PR_URL})

if ! grep -Pq "^https://github.com/[-0-9a-zA-Z]+/[-0-9a-zA-Z]+/pull/[0-9]+$" <<<${PR_URL}; then
  echo "Error: Unknown format for PR_URL ! Only https://github.com/<orgname>/<reponame>/pull/<prnumber>[/files] format is accepted"
  exit 1
fi

if ! grep -Pq "^stable/([0-9]+\.)+x$" <<<${TARGET_BRANCH}; then
  echo "Error: Unknown format for TARGET_BRANCH ! Only stable/<numbers>.<numbers>.x] format is accepted"
  exit 1
fi

if ! grep -Pq "^(DEFAULT|exoplatform|Meeds-io)$" <<<${TARGET_ORGANIZATION}; then
  echo "Error: Unknown format for TARGET_ORGANIZATION ! Only DEFAULT, exoplatform or Meeds-io is accepted"
  exit 1
fi

PR_API_URL=$(sed -e 's|github.com/|api.github.com/repos/|g' -e 's|pull|pulls|g' <<<${PR_URL})
PR_body=$(curl -XGET -s -L "$PR_API_URL"--header 'Accept: application/vnd.github.luke-cage-preview+json' --header "Authorization: Bearer ${GIT_TOKEN}" --header 'Content-Type: application/json')
isMerged=$(echo $PR_body | jq .merged | tr -d '"')
if [ "${isMerged}" = "false" ]; then
  echo "ERROR! Could not backport ummerged PR!"
  exit 1
fi 
echo "OK: Pull request is merged."
PR_title=$(echo $PR_body | jq .title | tr -d '"')
echo -e "INFO: PR's Title is:\n\"$PR_title\""
commitid=$(echo $PR_body | jq .merge_commit_sha | tr -d '"')
FULL_REPO_NAME=$(sed -e 's|https://github.com/||g' -e 's|/pull.*||g' <<<${PR_URL})
REPO_NAME=$(sed 's|.*/||g' <<< $FULL_REPO_NAME)
[ "${TARGET_ORGANIZATION}" = "DEFAULT" ] || FULL_REPO_NAME="${TARGET_ORGANIZATION}/${REPO_NAME}"
ssh_uri="git@github.com:$FULL_REPO_NAME.git"
echo "Cloning repository $FULL_REPO_NAME ..."
rm -rf $REPO_NAME &>/dev/null
set -e 
git clone $ssh_uri
cd $REPO_NAME
echo "Checking out to $TARGET_BRANCH branch..."
git checkout $TARGET_BRANCH
echo "Cherry-picking commit #$commitid ..."
git cherry-pick -x $commitid 
git commit --amend -m "$PR_title"
if [ -f "pom.xml" ]; then
  maven_cmd() {
    sudo docker run --rm --mount "type=bind,src=$(pwd),dst=/srv/ciagent/workspace" -v /opt/prdacc/mavenpatch/settings.xml:/home/ciagent/.m2/settings.xml:ro exoplatform/ci:jdk8-maven33 $*
  }
  echo "Maven projet has been detected. Compiling the project.."    
  maven_cmd install -Pexo-release
fi
echo "Pushing changes"
git push origin $TARGET_BRANCH
cd - &>/dev/null
rm -rf $REPO_NAME &>/dev/null