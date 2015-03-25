#!/bin/bash -eu

BRANCH=answers-addon
ISSUE=SWF-3106
ORIGIN_BRANCH=develop
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=4.2.x-SNAPSHOT
TARGET_VERSION_PREFIX=4.2.x

function createFB(){
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
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION_PREFIX-$2-$BRANCH-SNAPSHOT</version>" ""
  replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_VERSION_PREFIX-plfui-$BRANCH-SNAPSHOT</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_VERSION_PREFIX-commons-$BRANCH-SNAPSHOT</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_VERSION_PREFIX-ecms-$BRANCH-SNAPSHOT</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_VERSION_PREFIX-soc-$BRANCH-SNAPSHOT</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_VERSION_PREFIX-forum-$BRANCH-SNAPSHOT</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_VERSION_PREFIX-wiki-$BRANCH-SNAPSHOT</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_VERSION_PREFIX-cal-$BRANCH-SNAPSHOT</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_VERSION_PREFIX-integ-$BRANCH-SNAPSHOT</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_VERSION_PREFIX-plf-$BRANCH-SNAPSHOT</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_VERSION_PREFIX-pkgpub-$BRANCH-SNAPSHOT</org.exoplatform.platform.distributions.version>"
#  replaceInPom.sh "<org.exoplatform.ide.version>1.4.x-SNAPSHOT</org.exoplatform.ide.version>" "<org.exoplatform.ide.version>1.4.x-ide-$BRANCH-SNAPSHOT</org.exoplatform.ide.version>"
#  replaceInPom.sh "<org.exoplatform.depmgt.version>9-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>9-$BRANCH-SNAPSHOT</org.exoplatform.depmgt.version>"  
  git commit -m"$ISSUE : Create $BRANCH branch and update projects versions" -a
  git push origin $TARGET_BRANCH --set-upstream
  git checkout develop
  popd
}


createFB platform-ui plfui 
createFB commons commons 
createFB social soc 
createFB ecms ecms 
createFB wiki wiki 
createFB forum forum 
createFB calendar cal 
createFB integration integ 
createFB platform plf 
createFB platform-public-distributions pkgpub 
createFB platform-private-distributions pkgpriv 
