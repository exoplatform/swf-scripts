#!/bin/bash -eu

BRANCH=integration/4.3.x-translation-jipt

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}
#echo "FB source dirs = ${SWF_FB_REPOS}"

function deleteGitBranch(){
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
deleteGitBranch gatein-portal
deleteGitBranch platform-ui
deleteGitBranch commons
deleteGitBranch social
deleteGitBranch ecms
deleteGitBranch wiki
deleteGitBranch forum
deleteGitBranch calendar
deleteGitBranch integration
deleteGitBranch platform
deleteGitBranch platform-public-distributions
deleteGitBranch platform-private-distributions
popd
exit
