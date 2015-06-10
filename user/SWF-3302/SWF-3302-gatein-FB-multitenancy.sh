#!/bin/bash -eu

ISSUE=SWF-3302
BRANCH=PLF-multitenancy
ORIGIN_BRANCH=stable/4.3.x-PLF
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=4.3.x-PLF-SNAPSHOT
TARGET_VERSION_PREFIX=4.3.x


function createFBGateIn(){
  pushd $1
  git remote update --prune
  git reset --hard HEAD
  git fetch blessed
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
  printf "\e[1;33m# %s\e[m\n" "Modifying versions in the POMs ..."
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION_PREFIX-$BRANCH-SNAPSHOT</version>"
  #update kernel version
  replaceInPom.sh "<org.exoplatform.kernel.version>2.5.1-GA</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>2.5.x-$BRANCH-SNAPSHOT</org.exoplatform.kernel.version>"

  git commit -m "$ISSUE : Create $TARGET_BRANCH branch and update projects versions" -a
  git push origin $TARGET_BRANCH --set-upstream
  
  popd
}


createFBGateIn gatein-portal
