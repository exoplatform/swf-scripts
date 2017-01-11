#!/bin/bash -ue

REMOTE=origin
REPLACE_WHAT="<version>7-RC01</version>"
REPLACE_BY="<version>7</version>"
COMMIT_MSG="RELEASE-175: Upgrade addons-parent-pom 7-RC01 -> 7"

SCRIPTDIR=$(cd $(dirname "$0"); pwd)

function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  pushd $1
  git remote update 
  git co develop
  git pullr
  git reset --hard origin/develop

  local LOCAL_BRANCH=$2
  local REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH

  git checkout $LOCAL_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $LOCAL_BRANCH $REMOTE/$LOCAL_BRANCH
  else
    printf "\e[1;35m# %s\e[m\n" "WARNING : the ${LOCAL_BRANCH} branch already exists so we reuse it (you have 5 seconds to cancel with CTRL+C) ..."
    sleep 5
  fi
  git pullr
  git reset --hard $REMOTE_BRANCH
	#git branch --set-upstream-to=$REMOTE/$LOCAL_BRANCH $LOCAL_BRANCH

  $SCRIPTDIR/../replaceInFile.sh "$REPLACE_WHAT" "$REPLACE_BY" "pom.xml -not -wholename \"*/target/*\""
  git diff
  pause "Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  git push $REMOTE

  popd
}

#updateProject answers stable/1.2.x
#updateProject cas-addon stable/1.2.x
#updateProject chat-application stable/1.4.x
#updateProject cmis-addon stable/4.4.x
#updateProject crash-addon stable/4.4.x
updateProject josso-addon stable/1.2.x
updateProject openam-addon stable/1.2.x
updateProject remote-edit stable/1.2.x
updateProject saml2-addon stable/1.2.x
updateProject spnego-addon stable/1.2.x
updateProject task stable/1.2.x
updateProject wcm-template-pack stable/1.1.x
updateProject weemo-extension stable/1.4.x