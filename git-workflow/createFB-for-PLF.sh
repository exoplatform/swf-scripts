#!/bin/bash -eu

# Create Git Feature Branches for PLF projects

BRANCH=forum-redesign
ISSUE=SWF-3786
ORIGIN_BRANCH=develop
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=4.4.x-SNAPSHOT
TARGET_VERSION_PREFIX=4.4.x-$BRANCH

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}

function createFB(){
  local repo_name=$1
  printf "\e[1;33m########################################\e[m\n"
  printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
  printf "\e[1;33m########################################\e[m\n"
  pushd ${repo_name}

  # Remove all branches but the origin one
#  git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
  printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
  #git checkout $ORIGIN_BRANCH
  #git branch -D $TARGET_BRANCH
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
    printf "\e[1;35m# %s\e[m\n" "WARNING : the ${TARGET_BRANCH} branch already exists so we will delete it (you have 5 seconds to cancel with CTRL+C) ..."
    sleep 5
    git checkout $ORIGIN_BRANCH
    git branch -D $TARGET_BRANCH
    git checkout -b $TARGET_BRANCH
  fi
  set -e
  printf "\e[1;33m# %s\e[m\n" "Modifying versions in the POMs ..."
  $SCRIPTDIR/../replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION_PREFIX-SNAPSHOT</version>" ""
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>"
  #replaceInPom.sh "<org.exoplatform.depmgt.version>12-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>12-$BRANCH-SNAPSHOT</org.exoplatform.depmgt.version>"
  # for PLF Trial
  #replaceInPom.sh "<addon.exo.tasks.version>1.2.x-SNAPSHOT</addon.exo.tasks.version>" "<addon.exo.tasks.version>1.2.x-$BRANCH-SNAPSHOT</addon.exo.tasks.version>"
  #replaceInPom.sh "<version>1.2.x-SNAPSHOT</version>" "<version>1.2.x-$BRANCH-SNAPSHOT</version>" ""
  #replaceInPom.sh "<version>1.1.x-SNAPSHOT</version>" "<version>1.1.x-$BRANCH-SNAPSHOT</version>" ""

  printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ..."
  git commit -m "$ISSUE: Create $BRANCH branch and update projects versions (phase 2)" -a
  git push origin $TARGET_BRANCH --set-upstream
  git checkout develop
  popd
}

pushd ${SWF_FB_REPOS}

createFB platform-ui
createFB commons
createFB social
createFB ecms
createFB wiki
createFB forum
createFB calendar
createFB integration
createFB platform
createFB platform-public-distributions
createFB platform-private-distributions

popd
