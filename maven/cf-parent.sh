#!/bin/bash -ue

REMOTE=origin
#REPLACE_WHAT="<org.gatein.portal.version>3.5.10.Final-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>3.5.11.Final-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG="Update Gatein 3.5.10.Final-SNAPSHOT -> 3.5.10.Final-SNAPSHOT"
REPLACE_WHAT="<version>17-RC01</version>"
REPLACE_BY="<version>17</version>"
COMMIT_MSG="SWF-4454: Release maven parent pom for 5.1.0-GA"
#REPLACE_WHAT="<version>13-SNAPSHOT</version>"
#REPLACE_BY="<version>13</version>"
#COMMIT_MSG="Use maven-parent-pom 13"

SCRIPTDIR=$(cd $(dirname "$0"); pwd)

function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update 
  git checkout develop
   
  local LOCAL_BRANCH=$2
  local REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH

  git branch -D $LOCAL_BRANCH
  git checkout -b $LOCAL_BRANCH $REMOTE/$LOCAL_BRANCH
  git reset --hard $REMOTE_BRANCH
  git pull
	#git branch --set-upstream-to=$REMOTE/$LOCAL_BRANCH $LOCAL_BRANCH

  $SCRIPTDIR/../replaceInFile.sh "$REPLACE_WHAT" "$REPLACE_BY" "pom.xml -not -wholename \"*/target/*\""
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push $REMOTE

  popd
}

updateProject kernel stable/5.1.x
updateProject core stable/5.1.x
updateProject ws stable/5.1.x
updateProject jcr stable/5.1.x
