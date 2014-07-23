#!/bin/bash -ue

REMOTE=blessed
LOCAL_BRANCH=stable/4.0.x
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
#REPLACE_WHAT="<org.gatein.portal.version>3.5.10.Final-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>3.5.11.Final-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG="Update Gatein 3.5.10.Final-SNAPSHOT -> 3.5.10.Final-SNAPSHOT"
REPLACE_WHAT="<org.exoplatform.depmgt.version>7.5</org.exoplatform.depmgt.version>"
REPLACE_BY="<org.exoplatform.depmgt.version>7.6</org.exoplatform.depmgt.version>"
COMMIT_MSG="Upgrade maven-depmgt-pom 7.5 -> 7.6"
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

  replaceInPom.sh "$REPLACE_WHAT" "$REPLACE_BY"
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push 

  popd
}

#updateProject maven-depmgt-pom
updateProject platform-ui
updateProject commons
updateProject ecms
updateProject wiki
updateProject forum
updateProject social
updateProject calendar
updateProject integration
updateProject platform
#updateProject platform-public-distributions
#updateProject ide
#updateProject platform-private-distributions
