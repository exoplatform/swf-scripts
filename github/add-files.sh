#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=develop
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
COMMIT_MSG="SWF-3886: Add LGPL license file"

SCRIPTDIR=$(cd $(dirname "$0"); pwd)

function pause(){
   read -p "$*"
}

addFileToProject (){
  echo "================================================================================"
  pushd $1
  git remote update --prune
  git checkout $LOCAL_BRANCH
  git clean -df && git pullr
  git reset --hard $REMOTE_BRANCH

  cp /tmp/exo/files/LICENSE .
  git add LICENSE
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push $REMOTE

  popd
}

addFileToProject maven-sandbox-project
addFileToProject gatein-wci
addFileToProject kernel
addFileToProject core
addFileToProject ws
addFileToProject jcr
addFileToProject jcr-services
addFileToProject gatein-sso
addFileToProject gatein-pc
addFileToProject gatein-portal
addFileToProject maven-depmgt-pom
addFileToProject docs-style
addFileToProject platform-ui
addFileToProject commons
addFileToProject social
addFileToProject ecms
addFileToProject wiki
addFileToProject forum
addFileToProject calendar
addFileToProject integration
addFileToProject platform
addFileToProject platform-public-distributions

addFileToProject addons-manager
addFileToProject answers
addFileToProject cas-addon
addFileToProject cmis-addon
addFileToProject crash-addon
addFileToProject exo-es-embedded
addFileToProject openam-addon
addFileToProject remote-edit
addFileToProject saml2-addon
addFileToProject spnego-addon
addFileToProject task
addFileToProject wcm-template-pack

addFileToProject maven-parent-pom
addFileToProject cf-parent