#!/bin/bash -eu

BRANCH=4.3.x
ISSUE=SWF-3499
ORIGIN_BRANCH=develop
TARGET_BRANCH=release/$BRANCH
# Versions to find
ORIGIN_VERSION=4.3.x-SNAPSHOT
ORIGIN_GATEIN_VERSION=4.3.x-PLF-SNAPSHOT
ORIGIN_DEPGMT_VERSION=11-SNAPSHOT
# And, for release branch, replace with:
TARGET_PLF_VERSION=4.3.x-RC-SNAPSHOT
TARGET_GATEIN_VERSION=4.3.x-PLF-RC-SNAPSHOT
TARGET_DEPGMT_VERSION=11-RC-SNAPSHOT

# And, for next dev version, replace with:
NEXT_DEVELOP_PLF_VERSION=4.4.x-SNAPSHOT
NEXT_DEVELOP_GATEIN_VERSION=4.4.x-PLF-SNAPSHOT
NEXT_DEVELOP_DEPGMT_VERSION=12-SNAPSHOT


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
  printf "\e[1;33m# %s\e[m\n" "Modifying versions in the POMs ..."
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_PLF_VERSION-SNAPSHOT</version>" ""

  # PLF Projects
  replaceInPom.sh "<org.exoplatform.doc.doc-style.version>$ORIGIN_VERSION</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>$TARGET_PLF_VERSION</org.exoplatform.doc.doc-style.version>"
  replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_PLF_VERSION</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_PLF_VERSION</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_PLF_VERSION</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_PLF_VERSION</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_PLF_VERSION</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_PLF_VERSION</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_PLF_VERSION</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_PLF_VERSION</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_PLF_VERSION</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_PLF_VERSION</org.exoplatform.platform.distributions.version>"

  # GateIn
  replaceInPom.sh "<org.gatein.portal.version>$ORIGIN_GATEIN_VERSION</org.gatein.portal.version>" "<org.gatein.portal.version>$TARGET_GATEIN_VERSION</org.gatein.portal.version>"
  # POM depgmt
  replaceInPom.sh "<org.exoplatform.depmgt.version>$ORIGIN_DEPGMT_VERSION</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>$TARGET_DEPGMT_VERSION</org.exoplatform.depmgt.version>"

  ## Commit and Push Release Branch and update versions
  printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ..."
  git commit -m"$ISSUE: Create $TARGET_BRANCH branch and update projects versions" -a
  git push blessed $TARGET_BRANCH --set-upstream

  ################################################
  #
  # Update dev version for next development
  #
  #
  git checkout $ORIGIN_BRANCH
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$NEXT_DEVELOP_PLF_VERSION-SNAPSHOT</version>" ""

  # PLF Projects
  replaceInPom.sh "<org.exoplatform.doc.doc-style.version>$ORIGIN_VERSION</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.doc.doc-style.version>"
  replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$NEXT_DEVELOP_PLF_VERSION</org.exoplatform.platform.distributions.version>"

  # GateIn
  replaceInPom.sh "<org.gatein.portal.version>$ORIGIN_GATEIN_VERSION</org.gatein.portal.version>" "<org.gatein.portal.version>$NEXT_DEVELOP_GATEIN_VERSION</org.gatein.portal.version>"
  # POM depgmt
  replaceInPom.sh "<org.exoplatform.depmgt.version>$ORIGIN_DEPGMT_VERSION</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>$NEXT_DEVELOP_DEPGMT_VERSION</org.exoplatform.depmgt.version>"

  printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $NEXT_DEVELOP_PLF_VERSION version on $ORIGIN_BRANCH branch to origin ..."
  git commit -m "$ISSUE: Update projects versions to $NEXT_DEVELOP_PLF_VERSION for next development version" -a
  git push origin $ORIGIN_BRANCH --set-upstream

  popd
}

pushd ${SWF_FB_REPOS}

createRB maven-sandbox-project
#createRB gatein-portal
#createRB docs-style
#createRB platform-ui
#createRB commons
#createRB social
#createRB ecms
#createRB wiki
#createRB forum
#createRB calendar
#createRB integration
#createRB platform
#createRB platform-public-distributions
#createRB platform-private-distributions

popd
