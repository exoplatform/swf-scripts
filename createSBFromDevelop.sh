#!/bin/bash -eu

ISSUE=SWF-3274
CURRENT_DEVELOP_VERSION_PREFIX=4.2.x
NEXT_DEVELOP_VERSION_PREFIX=4.3.x
ORIGIN_BRANCH=origin/develop
STABLE_BRANCH=stable/$CURRENT_DEVELOP_VERSION_PREFIX


function createSBFromDevelop(){
  echo "########################################"
  echo "# Repository: $1"
  echo "########################################"
  pushd $1

  git remote update --prune
  git reset --hard HEAD
  git checkout develop
  git reset --hard HEAD
  git pull
  set +e
  git checkout $STABLE_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $STABLE_BRANCH
  fi
  set -e
  replaceInPom.sh "<version>.*-SNAPSHOT</version>" "<version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</version>"
  replaceInPom.sh "<org.exoplatform.platform-ui.version>.*-SNAPSHOT</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>.*-SNAPSHOT</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>.*-SNAPSHOT</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>.*-SNAPSHOT</org.exoplatform.social.version>" "<org.exoplatform.social.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>.*-SNAPSHOT</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>.*-SNAPSHOT</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>.*-SNAPSHOT</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>.*-SNAPSHOT</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>.*-SNAPSHOT</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>.*-SNAPSHOT</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>"
  replaceInPom.sh "<org.gatein.portal.version>.*-PLF-SNAPSHOT</org.gatein.portal.version>" "<org.gatein.portal.version>$CURRENT_DEVELOP_VERSION_PREFIX-PLF-SNAPSHOT</org.gatein.portal.version>"
 #  replaceInPom.sh "<org.exoplatform.ide.version>1.4.x-SNAPSHOT</org.exoplatform.ide.version>" "<org.exoplatform.ide.version>1.4.x-ide-$BRANCH-SNAPSHOT</org.exoplatform.ide.version>"
 #  replaceInPom.sh "<org.exoplatform.depmgt.version>9-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>9-$BRANCH-SNAPSHOT</org.exoplatform.depmgt.version>"
  git add -A
  git diff-index --quiet HEAD || git commit -m "$ISSUE : Create $STABLE_BRANCH branch and update projects versions"
  git push origin $STABLE_BRANCH --set-upstream

  #update project version on develop branch
  git checkout develop
  replaceInPom.sh "<version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</version>" "<version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</version>"
  replaceInPom.sh "<org.exoplatform.platform-ui.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>" "<org.exoplatform.social.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>"
  replaceInPom.sh "<org.gatein.portal.version>$CURRENT_DEVELOP_VERSION_PREFIX-PLF-SNAPSHOT</org.gatein.portal.version>" "<org.gatein.portal.version>$NEXT_DEVELOP_VERSION_PREFIX-PLF-SNAPSHOT</org.gatein.portal.version>"
  #  replaceInPom.sh "<org.exoplatform.ide.version>1.4.x-SNAPSHOT</org.exoplatform.ide.version>" "<org.exoplatform.ide.version>1.4.x-ide-$BRANCH-SNAPSHOT</org.exoplatform.ide.version>"
  #  replaceInPom.sh "<org.exoplatform.depmgt.version>9-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>9-$BRANCH-SNAPSHOT</org.exoplatform.depmgt.version>"
  git commit -m "$ISSUE : Update projects versions for next development" -a
  git push origin develop

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
