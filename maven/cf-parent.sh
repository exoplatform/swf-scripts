#!/bin/bash -ue

REMOTE=origin
#REPLACE_WHAT="<org.gatein.portal.version>3.5.10.Final-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>3.5.11.Final-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG="Update Gatein 3.5.10.Final-SNAPSHOT -> 3.5.10.Final-SNAPSHOT"
REPLACE_WHAT="<version>15-RC02</version>"
REPLACE_BY="<version>15</version>"
COMMIT_MSG="RELEASE-175: Upgrade cf-parent 15-RC02 -> 15"
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
  git co develop
   
  local LOCAL_BRANCH=$2
  local REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH

  git branch -D $LOCAL_BRANCH
  git checkout -b $LOCAL_BRANCH $REMOTE/$LOCAL_BRANCH
  git reset --hard $REMOTE_BRANCH
  git pullr
	#git branch --set-upstream-to=$REMOTE/$LOCAL_BRANCH $LOCAL_BRANCH

  $SCRIPTDIR/../replaceInFile.sh "$REPLACE_WHAT" "$REPLACE_BY" "pom.xml -not -wholename \"*/target/*\""
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push $REMOTE

  popd
}

updateProject kernel stable/2.6.x
updateProject core stable/2.7.x
updateProject ws stable/2.5.x
updateProject jcr stable/1.17.x
updateProject jcr-services stable/1.17.x