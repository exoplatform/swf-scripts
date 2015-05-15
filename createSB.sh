#!/bin/bash -eu

ISSUE=SWF-3274
ORIGIN_VERSION=4.2.0-RC1
TARGET_VERSION_PREFIX=4.2.x
ORIGIN_BRANCH=release/$ORIGIN_VERSION
TARGET_BRANCH=stable/$TARGET_VERSION_PREFIX


function createSB(){
  echo "########################################"
  echo "# Repository: $1"
  echo "########################################"
  pushd $1

  git remote update --prune
  git reset --hard HEAD
  git checkout $ORIGIN_BRANCH
  git reset --hard HEAD
  git pull
  set +e
  git checkout $TARGET_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $TARGET_BRANCH
  fi
  set -e
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION_PREFIX-SNAPSHOT</version>" ""
  replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>"
  replaceInPom.sh "<org.gatein.portal.version>$ORIGIN_VERSION-PLF</org.gatein.portal.version>" "<org.gatein.portal.version>$TARGET_VERSION_PREFIX-PLF-SNAPSHOT</org.gatein.portal.version>"
#  replaceInPom.sh "<org.exoplatform.ide.version>1.4.x-SNAPSHOT</org.exoplatform.ide.version>" "<org.exoplatform.ide.version>1.4.x-ide-$BRANCH-SNAPSHOT</org.exoplatform.ide.version>"
#  replaceInPom.sh "<org.exoplatform.depmgt.version>9-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>9-$BRANCH-SNAPSHOT</org.exoplatform.depmgt.version>"
  git commit -m"$ISSUE : Create $TARGET_BRANCH branch and update projects versions" -a
  git push origin $TARGET_BRANCH --set-upstream
  git checkout develop
  popd
}


createSB platform-ui
createSB commons
createSB social
createSB ecms
createSB wiki
createSB forum
createSB calendar
createSB integration
createSB platform
createSB platform-public-distributions
createSB platform-private-distributions
