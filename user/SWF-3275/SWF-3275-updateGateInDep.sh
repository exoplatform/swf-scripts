#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=feature/oauth
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
REPLACE_WHAT="<org.gatein.portal.version>4.3.x-PLF-SNAPSHOT</org.gatein.portal.version>"
REPLACE_BY="<org.gatein.portal.version>4.3.x-PLF-oauth-SNAPSHOT</org.gatein.portal.version>"
COMMIT_MSG="SWF-3275: update gatein-portal version"


function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update

  git checkout $LOCAL_BRANCH
  git reset --hard $REMOTE_BRANCH

  replaceInPom.sh "$REPLACE_WHAT" "$REPLACE_BY"
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
