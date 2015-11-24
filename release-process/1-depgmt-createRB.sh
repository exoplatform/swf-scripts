#!/bin/bash -eu

BRANCH=11.x
ISSUE=SWF-3499
ORIGIN_BRANCH=develop
TARGET_BRANCH=release/$BRANCH
ORIGIN_VERSION=11-SNAPSHOT
TARGET_VERSION=11-RC-SNAPSHOT
NEXT_DEVELOP_VERSION=12-SNAPSHOT

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}

function createRB(){
  local repo_name=$1
  printf "\e[1;33m########################################\e[m\n"
  printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
  printf "\e[1;33m########################################\e[m\n"
  pushd ${repo_name}

  # Remove all branches but the origin one
#  git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
  printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
  git remote update --prune
  git reset --hard HEAD
  git checkout $ORIGIN_BRANCH
  git reset --hard HEAD
  git pull
  printf "\e[1;33m# %s\e[m\n" "Testing if ${TARGET_BRANCH} branch doesn't already exists and reuse it ..."
  set +e
  git checkout $TARGET_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $TARGET_BRANCH
  else
    printf "\e[1;35m# %s\e[m\n" "WARNING : the ${TARGET_BRANCH} branch already exists so we reuse it (you have 5 seconds to cancel with CTRL+C) ..."
    sleep 5
  fi
  set -e
  printf "\e[1;33m# %s\e[m\n" "Modifying versions in the POMs for Release Branch ..."
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION</version>"

  printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ..."
  git commit -m "$ISSUE: Create $TARGET_BRANCH branch and update projects versions" -a
  git push origin $TARGET_BRANCH --set-upstream

  ## Update dev version for next development
  git checkout $ORIGIN_BRANCH
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$NEXT_DEVELOP_VERSION</version>"
  printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $NEXT_DEVELOP_VERSION version on $ORIGIN_VERSION branch to origin ..."
  git commit -m "$ISSUE: Update projects versions to $NEXT_DEVELOP_VERSION for next development version" -a
  git push origin $ORIGIN_BRANCH --set-upstream

  popd
}

pushd ${SWF_FB_REPOS}

createRB maven-depmgt-pom

popd
