#!/bin/bash -eu
# Create Feature Branches for Core Foundation projects

ISSUE=SWF-3869
BRANCH=develop
TARGET_BRANCH=update/5.0.x

#kernel versions
KERNEL_ORIGIN_BRANCH=develop
KERNEL_ORIGIN_VERSION=2.7.x-SNAPSHOT
KERNEL_TARGET_VERSION=5.0.x-SNAPSHOT

#core versions
CORE_ORIGIN_BRANCH=develop
CORE_ORIGIN_VERSION=2.8.x-SNAPSHOT
CORE_TARGET_VERSION=5.0.x-SNAPSHOT

#ws versions
WS_ORIGIN_BRANCH=develop
WS_ORIGIN_VERSION=2.6.x-SNAPSHOT
WS_TARGET_VERSION=5.0.x-SNAPSHOT

#jcr versions
JCR_ORIGIN_BRANCH=develop
JCR_ORIGIN_VERSION=1.18.x-SNAPSHOT
JCR_TARGET_VERSION=5.0.x-SNAPSHOT

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

function createFBCoreFoundation(){
  pushd $1

  originBranch=$1_ORIGIN_BRANCH

  git remote update --prune
  git reset --hard HEAD
  git fetch blessed
  git fetch origin
  git checkout ${!originBranch}
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
  #project version
  versionToReplace=$1_ORIGIN_VERSION
  targetVersion=$1_TARGET_VERSION
  printf "versionToReplace ${versionToReplace}"
  printf "!versionToReplace ${!versionToReplace}"
  $SCRIPTDIR/../replaceInFile.sh "<version>${!versionToReplace}</version>" "<version>${!targetVersion}</version>" "pom.xml -not -wholename \"*/target/*\""
  # Parent POM version
  $SCRIPTDIR/../replaceInFile.sh "<version>15-RC02</version>" "<version>16.x-SNAPSHOT</version>" "pom.xml -not -wholename \"*/target/*\""

  #dependencies versions
  $SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.kernel.version>${KERNEL_ORIGIN_VERSION}</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>${KERNEL_TARGET_VERSION}</org.exoplatform.kernel.version>" "pom.xml -not -wholename \"*/target/*\""
  $SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.core.version>${CORE_ORIGIN_VERSION}</org.exoplatform.core.version>" "<org.exoplatform.core.version>${CORE_TARGET_VERSION}</org.exoplatform.core.version>" "pom.xml -not -wholename \"*/target/*\""
  $SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.ws.version>${WS_ORIGIN_VERSION}</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>${WS_TARGET_VERSION}</org.exoplatform.ws.version>" "pom.xml -not -wholename \"*/target/*\""
  $SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.jcr.version>${JCR_ORIGIN_VERSION}</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>${JCR_TARGET_VERSION}</org.exoplatform.jcr.version>" "pom.xml -not -wholename \"*/target/*\""

  git commit -m "$ISSUE: Update all PLF components versions to 5.0.x-SNAPSHOT version" -a
  #git push origin $TARGET_BRANCH --set-upstream

  popd
}

createFBCoreFoundation KERNEL
createFBCoreFoundation CORE
createFBCoreFoundation WS
createFBCoreFoundation JCR
