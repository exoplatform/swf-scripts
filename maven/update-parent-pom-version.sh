#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=develop
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
#REPLACE_WHAT="<org.gatein.portal.version>3.5.10.Final-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>3.5.11.Final-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG="Update Gatein 3.5.10.Final-SNAPSHOT -> 3.5.10.Final-SNAPSHOT"
REPLACE_WHAT="<version>14</version>"
REPLACE_BY="<version>15</version>"
COMMIT_MSG="PLF-6410: Upgrade maven-parent-pom 14 -> 15"
#REPLACE_WHAT="<version>13-SNAPSHOT</version>"
#REPLACE_BY="<version>13</version>"
#COMMIT_MSG="Use maven-parent-pom 13"

function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update

  git checkout $LOCAL_BRANCH
  git reset --hard $REMOTE_BRANCH
	git branch --set-upstream-to=$REMOTE/$LOCAL_BRANCH $LOCAL_BRANCH

  $SCRIPTDIR/../replaceInPom.sh "$REPLACE_WHAT" "$REPLACE_BY"
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  #git push $REMOTE

  popd
}

updateProject docs-style
updateProject platform-ui
updateProject commons
updateProject ecms
updateProject social
updateProject wiki
updateProject calendar
updateProject forum
updateProject integration
updateProject platform
updateProject platform-public-distributions
updateProject platform-private-distributions
