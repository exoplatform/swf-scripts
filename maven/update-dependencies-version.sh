#!/bin/bash -ue

REMOTE=origin
LOCAL_BRANCH=feature/enterprise-skin
REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
REPLACE_WHAT="<org.exoplatform.gatein.portal.version>5.0.x-SNAPSHOT</org.exoplatform.gatein.portal.version>"
REPLACE_BY="<org.exoplatform.gatein.portal.version>5.0.x-enterprise-skin-SNAPSHOT</org.exoplatform.gatein.portal.version>"
COMMIT_MSG="SWF-3881: [FB enterprise-skin] update GateIn Portal dependency version"

SCRIPTDIR=$(cd $(dirname "$0"); pwd)

function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update --prune
  git checkout $LOCAL_BRANCH
  git clean -df && git pullr
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
