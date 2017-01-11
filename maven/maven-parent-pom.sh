#!/bin/bash -ue

REMOTE=blessed
REPLACE_WHAT="<version>16-RC01</version>"
REPLACE_BY="<version>16</version>"
COMMIT_MSG="RELEASE-175: Upgrade maven-parent-pom 16-RC01 -> 16"

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

updateProject docs-style stable/4.4.x
updateProject platform-ui stable/4.4.x
updateProject commons stable/4.4.x
updateProject social stable/4.4.x
updateProject ecms stable/4.4.x
updateProject wiki stable/4.4.x
updateProject forum stable/4.4.x
updateProject calendar stable/4.4.x
updateProject integration stable/4.4.x
updateProject platform stable/4.4.x
updateProject platform-public-distributions stable/4.4.x
updateProject platform-private-distributions stable/4.4.x
updateProject platform-private-trial-distributions stable/4.4.x