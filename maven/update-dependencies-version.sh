#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=feature/doc-preview-search
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
REPLACE_WHAT="<org.exoplatform.platform-ui.version>4.4.x-SNAPSHOT</org.exoplatform.platform-ui.version>"
REPLACE_BY="<org.exoplatform.platform-ui.version>4.4.x-doc-preview-search-SNAPSHOT</org.exoplatform.platform-ui.version>"
COMMIT_MSG="SWF-3682: Update platform-ui version to 4.4.x-doc-preview-search-SNAPSHOT"


function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update

  git checkout $LOCAL_BRANCH
  git reset --hard $REMOTE_BRANCH

  $SCRIPTDIR/../replaceInPom.sh "$REPLACE_WHAT" "$REPLACE_BY"
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
