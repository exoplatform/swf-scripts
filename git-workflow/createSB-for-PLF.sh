#!/bin/bash -eu

ISSUE=SWF-3837
CURRENT_DEVELOP_VERSION_PREFIX=4.4.x
NEXT_DEVELOP_VERSION_PREFIX=4.5.x
ORIGIN_BRANCH=develop
STABLE_BRANCH=stable/$CURRENT_DEVELOP_VERSION_PREFIX

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)


function createSBFromDevelop(){
  echo "########################################"
  echo "# Repository: $1"
  echo "########################################"
  pushd $1

  git remote update --prune
  git reset --hard HEAD
  git checkout $ORIGIN_BRANCH
  git reset --hard HEAD
  git pull
  #update project version on develop branch
  git checkout develop
  $SCRIPTDIR/../replaceInPom.sh "<version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</version>" "<version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</version>"
  $SCRIPTDIR/../replaceInPom.sh "<version>16-RC01</version>" "<version>17-SNAPSHOT</version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.depmgt.version>12-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>13-SNAPSHOT</org.exoplatform.depmgt.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.jcr.version>1.17.x-SNAPSHOT</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>1.18.x-SNAPSHOT</org.exoplatform.jcr.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ws.version>2.5.x-SNAPSHOT</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>2.6.x-SNAPSHOT</org.exoplatform.ws.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.core.version>2.7.x-SNAPSHOT</org.exoplatform.core.version>" "<org.exoplatform.core.version>2.8.x-SNAPSHOT</org.exoplatform.core.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.kernel.version>2.6.x-SNAPSHOT</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>2.7.x-SNAPSHOT</org.exoplatform.kernel.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.commons.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.commons.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform-ui.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform-ui.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ecms.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.ecms.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.social.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>" "<org.exoplatform.social.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.social.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.forum.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.forum.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.wiki.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.wiki.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.calendar.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.calendar.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.integ.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.integ.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.distributions.version>$CURRENT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$NEXT_DEVELOP_VERSION_PREFIX-SNAPSHOT</org.exoplatform.platform.distributions.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.gatein.portal.version>$CURRENT_DEVELOP_VERSION_PREFIX-PLF-SNAPSHOT</org.gatein.portal.version>" "<org.gatein.portal.version>$NEXT_DEVELOP_VERSION_PREFIX-PLF-SNAPSHOT</org.gatein.portal.version>"
  git commit -m "$ISSUE: Update projects versions to 4.5.x for next development" -a
  git push origin develop

  popd
}


#createSBFromDevelop platform-ui
#createSBFromDevelop docs-style
#createSBFromDevelop commons
#createSBFromDevelop social
createSBFromDevelop ecms
createSBFromDevelop wiki
createSBFromDevelop forum
createSBFromDevelop calendar
createSBFromDevelop integration
createSBFromDevelop platform
createSBFromDevelop platform-public-distributions
createSBFromDevelop platform-private-distributions
createSBFromDevelop platform-private-trial-distributions