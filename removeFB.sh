#!/bin/bash -eu

BRANCH=feature/user-profile-redesign

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}
#echo "FB source dirs = ${SWF_FB_REPOS}"

function deleteFB(){
  echo "########################################"
  echo "##### repo : $(basename $1)"
  echo "########################################"
  pushd $1
  git checkout develop
  git branch -D $BRANCH || true
  git push origin --delete $BRANCH || true
  popd
}

pushd ${SWF_FB_REPOS}
#deleteFB maven-depmgt-pom
deleteFB platform-ui
deleteFB commons
deleteFB social
deleteFB ecms
deleteFB wiki
deleteFB forum
deleteFB calendar
deleteFB integration
deleteFB platform
deleteFB platform-public-distributions
deleteFB platform-private-distributions
popd
exit
