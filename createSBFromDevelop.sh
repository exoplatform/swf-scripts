#!/bin/bash -eu

ISSUE=SWF-3274
ORIGIN_VERSION=develop
TARGET_VERSION_PREFIX=4.2.x
ORIGIN_BRANCH=origin/$ORIGIN_VERSION
TARGET_BRANCH=stable/$TARGET_VERSION_PREFIX


function createSBFromDevelop(){
  echo "########################################"
  echo "# Repository: $1"
  echo "########################################"
  pushd $1

  git remote update --prune
  git reset --hard HEAD
  git checkout $ORIGIN_VERSION
  git reset --hard HEAD
  git pull
  set +e
  git checkout $TARGET_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $TARGET_BRANCH
  fi
  set -e
  git push origin $TARGET_BRANCH --set-upstream
  git checkout develop
  popd
}


createSBFromDevelop platform-ui
createSBFromDevelop commons
createSBFromDevelop social
createSBFromDevelop ecms
createSBFromDevelop wiki
createSBFromDevelop forum
createSBFromDevelop calendar
createSBFromDevelop integration
createSBFromDevelop platform
createSBFromDevelop platform-public-distributions
createSBFromDevelop platform-private-distributions
