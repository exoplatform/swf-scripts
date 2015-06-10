#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=feature/multitenancy
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
#REPLACE_WHAT="<org.gatein.portal.version>3.5.10.Final-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>3.5.11.Final-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG="Update Gatein 3.5.10.Final-SNAPSHOT -> 3.5.10.Final-SNAPSHOT"
#REPLACE_WHAT="<org.exoplatform.depmgt.version>10-SNAPSHOT</org.exoplatform.depmgt.version>"
#REPLACE_BY="<org.exoplatform.depmgt.version>11-SNAPSHOT</org.exoplatform.depmgt.version>"
#REPLACE_WHAT="<org.gatein.portal.version>4.3.x-PLF-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>4.3.x-PLF-oauth-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG2="SWF-3289: Upgrade maven-depmgt-pom 10-SNAPSHOT -> 11-SNAPSHOT"
COMMIT_MSG="SWF-3302: update Core Foundation versions"
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
  git push --set-upstream origin $REMOTE_BRANCH

  replaceInPom.sh "<org.exoplatform.kernel.version>2.5.1-GA</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>2.5.x-PLF-multitenancy-SNAPSHOT</org.exoplatform.kernel.version>"
  replaceInPom.sh "<org.exoplatform.core.version>2.6.1-GA</org.exoplatform.core.version>" "<org.exoplatform.core.version>2.6.x-PLF-multitenancy-SNAPSHOT</org.exoplatform.core.version>"
  replaceInPom.sh "<org.exoplatform.ws.version>2.4.1-GA</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>2.4.x-PLF-multitenancy-SNAPSHOT</org.exoplatform.ws.version>"
  replaceInPom.sh "<org.exoplatform.jcr.version>1.16.1-GA</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>1.16.x-PLF-multitenancy-SNAPSHOT</org.exoplatform.jcr.version>"
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push $REMOTE

  popd
}

#updateProject gatein-portal
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
