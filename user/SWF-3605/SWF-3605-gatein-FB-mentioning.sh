#!/bin/bash -eu

ISSUE=SWF-3605
BRANCH=mentioning
ORIGIN_BRANCH=develop
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=4.4.x-PLF-SNAPSHOT
TARGET_VERSION_PREFIX=4.4.x-PLF

#kernel versions
KERNEL_ORIGIN_VERSION=2.6.x-SNAPSHOT
KERNEL_TARGET_VERSION=2.6.x-$BRANCH-SNAPSHOT

#core versions
CORE_ORIGIN_VERSION=2.7.x-SNAPSHOT
CORE_TARGET_VERSION=2.7.x-$BRANCH-SNAPSHOT

#ws versions
WS_ORIGIN_VERSION=2.5.x-SNAPSHOT
WS_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT

#jcr versions
JCR_ORIGIN_VERSION=1.17.x-SNAPSHOT
JCR_TARGET_VERSION=1.17.x-$BRANCH-SNAPSHOT

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
  #dependencies versions
  replaceInPom.sh "<org.exoplatform.kernel.version>${KERNEL_ORIGIN_VERSION}</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>${KERNEL_TARGET_VERSION}</org.exoplatform.kernel.version>"
  replaceInPom.sh "<org.exoplatform.core.version>${CORE_ORIGIN_VERSION}</org.exoplatform.core.version>" "<org.exoplatform.core.version>${CORE_TARGET_VERSION}</org.exoplatform.core.version>"
  replaceInPom.sh "<org.exoplatform.ws.version>${WS_ORIGIN_VERSION}</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>${WS_TARGET_VERSION}</org.exoplatform.ws.version>"
  replaceInPom.sh "<org.exoplatform.jcr.version>${JCR_ORIGIN_VERSION}</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>${JCR_TARGET_VERSION}</org.exoplatform.jcr.version>"

  git commit -m "$ISSUE : Create $TARGET_BRANCH branch and update projects versions" -a
  git push origin $TARGET_BRANCH --set-upstream

  popd
}


createFBGateIn gatein-portal
