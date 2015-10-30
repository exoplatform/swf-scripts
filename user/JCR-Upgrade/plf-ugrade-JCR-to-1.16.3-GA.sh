#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=develop
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH

COMMIT_MSG="SWF-3473: Upgrade to JCR 1.16.3-GA"

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

  replaceInPom.sh "<org.exoplatform.kernel.version>2.5.2-GA</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>2.5.3-GA</org.exoplatform.kernel.version>"
  replaceInPom.sh "<org.exoplatform.core.version>2.6.2-GA</org.exoplatform.core.version>" "<org.exoplatform.core.version>2.6.3-GA</org.exoplatform.core.version>"
  replaceInPom.sh "<org.exoplatform.ws.version>2.4.2-GA</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>2.4.3-GA</org.exoplatform.ws.version>"
  replaceInPom.sh "<org.exoplatform.jcr.version>1.16.2-GA</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>1.16.3-GA</org.exoplatform.jcr.version>"
  replaceInPom.sh "<org.exoplatform.jcr-services.version>1.16.2-GA</org.exoplatform.jcr-services.version>" "<org.exoplatform.jcr-services.version>1.16.3-GA</org.exoplatform.jcr-services.version>"

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
