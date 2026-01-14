#!/bin/bash

# Requirement:
# GIT_TOKEN: ENV VAR: GIT API TOKEN
# REPOSITORIES: PARAMETER (STRING): exoplatform or meeds-io's repositories names with :Addon/PLF version
#    Example social:5.3.3,ecms:5.3.3
# TASK_ID: PARAMETER(NUMBERS): eXo Tribe Task's ID
if [ -z "${GIT_TOKEN}" ]; then
  echo "Error: GIT_TOKEN is not specified!"
  exit 1
fi

if [ -z "${REPOSITORIES}" ]; then
  echo "Error: Parameter REPOSITORIES are not specified!"
  exit 1
fi

if [ -z "${TASK_ID}" ]; then
  echo "Error: Parameter TASK_ID is not specified!"
  exit 1
fi

if ! grep -qP "^([-0-9a-zA-Z]+:[0-9]+(\.[0-9]+)*(\-[A-Za-z0-9]+)*\,?){1,30}$" <<<${REPOSITORIES}; then
  echo "Error: Unknown format for REPOSITORIES! Only <reponame1>:tagversion,<reponame2>:tagversion,...<reponameN>:tagversion[,] format are accepted"
  exit 1
fi

if ! grep -Pq "^[0-9]+$" <<<${TASK_ID}; then
  echo "Error: Unknown format for TASK_ID! Only digits are accepted"
  exit 1
fi

_REPOS=$(sed 's|,| |g' <<<${REPOSITORIES} | xargs)
echo "####################################"
echo "Patch Branch Creator for eXo Support"
echo "####################################"
echo ""
echo "Repositories: ${REPOSITORIES}"
echo ""
echo "####################################"
set -e
for i in ${_REPOS}; do
  echo ""
  echo "## Module: "$i
  repo="${i%%:*}"
  tagversion="${i#*:}"
  rm -rf ${repo} &>/dev/null
  ORGANIZATION="meeds-io"
  echo "Fetching suitable organization of ${repo}..."
  set +e
  if [ $(git ls-remote "git@github.com:${ORGANIZATION}/${repo}.git" ${tagversion} 2>/dev/null | wc -l) = "0" ]; then
    ORGANIZATION="exoplatform"
    if [ $(git ls-remote "git@github.com:${ORGANIZATION}/${repo}.git" ${tagversion} 2>/dev/null | wc -l) = "0" ]; then
      echo "Error: tag ${tagversion} does not exist! Abort."
      exit 1
    fi
  fi
  set -e

  echo "Checking ${ORGANIZATION}/${repo}:patch/${tagversion} existance..."
  if [ $(git ls-remote --heads "git@github.com:${ORGANIZATION}/${repo}.git" patch/${tagversion} | wc -l) -gt "0" ]; then
    echo "Error: Branch patch/${tagversion} already exist! Abort."
    exit 1
  fi
  echo "OK: patch/${tagversion} branch is not created."
  echo "Cloning ${ORGANIZATION}/${repo} repository..."
  git clone -b ${tagversion} --depth=1 "git@github.com:${ORGANIZATION}/${repo}.git"
  echo "Clone is OK. Checking if tag ${tagversion} does exist or not..."
  [[ "$(git --work-tree=${repo}/.git --git-dir=${repo}/.git tag)" == "${tagversion}" ]] && echo "OK: ${tagversion} does exist. Creating patch/${tagversion} branch..."
  git --work-tree=${repo}/.git --git-dir=${repo}/.git checkout -b patch/${tagversion} &>/dev/null
  echo "OK: patch/${tagversion} branch has been created locally."
  if [ -f "${repo}/pom.xml" ]; then
    maven_cmd() {
      sudo docker run --rm -v $(readlink -m ${repo}):/home -v /opt/prdacc/mavenpatch/settings.xml:/root/.m2/settings.xml --dns="8.8.8.8" --dns="8.8.8.4" --sysctl net.ipv6.conf.all.disable_ipv6=1 -w /home maven:3.9.12 mvn $*
    }
    echo "Maven projet has been detected. Adding \"-patched\" suffix to the project version..."
    maven_cmd -ntp versions:set -DgenerateBackupPoms=false -DnewVersion="${tagversion}-patched"
    cd ${repo}
    echo "OK: Suffix \"-patched\" has been added. Adding pom.xml files to Git staging area..."
    git diff ${tagversion} --name-only | grep -P pom.xml$ | xargs git add
    cd - &>/dev/null
    printf "OK: pom.xml files have been added! "
  fi
  echo "Initializing ${repo}/patches-changelog.txt file..."
  echo -e "              $(date +%Y-%m-%d) eXo Support <support@exoplatform.org> \n\n   # ${tagversion} Patches changelog: \n\n" >${repo}/patches-changelog.txt
  cd ${repo}
  git add patches-changelog.txt
  cd - &>/dev/null
  commit_msg="TASK-${TASK_ID}: Create Patch Branch for version ${tagversion}"
  echo "Creating commit: ${commit_msg}"
  git --work-tree=${repo}/.git --git-dir=${repo}/.git commit -m "${commit_msg}"
  echo "Pushing branch patch/${tagversion} to remote "
  git --work-tree=${repo}/.git --git-dir=${repo}/.git push -u origin patch/${tagversion} 2>&1 | grep -v remote
  echo "OK: Branch is pushed correctly. Adding Branch Protection rule to patch/${tagversion} branch..."
  curl -s -f -XPUT -L "https://api.github.com/repos/${ORGANIZATION}/${repo}/branches/patch%2F${tagversion}/protection" \
    --header 'Accept: application/vnd.github.luke-cage-preview+json' \
    --header "Authorization: Bearer ${GIT_TOKEN}" \
    --header 'Content-Type: application/json' \
    --data '{ "required_status_checks":{"strict": true,"contexts": ["PR Build"]},  "enforce_admins": true,  "required_pull_request_reviews": {"dismiss_stale_reviews": true,"required_approving_review_count": 1  },"restrictions": null}'
  echo "OK: Branch Protection added."
  rm -rf ${repo} &>/dev/null
done
