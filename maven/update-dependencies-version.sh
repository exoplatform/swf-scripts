#!/bin/bash -ue

REMOTE=blessed
LOCAL_BRANCH=stable/4.4.x
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
REPLACE_WHAT="<org.exoplatform.depmgt.version>12-SNAPSHOT</org.exoplatform.depmgt.version>"
REPLACE_BY="<org.exoplatform.depmgt.version>12.x-SNAPSHOT</org.exoplatform.depmgt.version>"
COMMIT_MSG="SWF-3882: Update maven-depmgt-pom to 12.x-SNAPSHOT"

SCRIPTDIR=$(cd $(dirname "$0"); pwd)

function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update

  git checkout $LOCAL_BRANCH
  git pullr
  git reset --hard $REMOTE_BRANCH

  $SCRIPTDIR/../replaceInFile.sh "$REPLACE_WHAT" "$REPLACE_BY" "pom.xml -not -wholename \"*/target/*\""
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push $REMOTE

  popd
}

updateProject platform-ui
updateProject commons
updateProject social
updateProject ecms
updateProject wiki
updateProject forum
updateProject calendar
updateProject integration
updateProject platform
updateProject platform-public-distributions
updateProject platform-private-distributions
