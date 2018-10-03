#!/bin/bash -ue

# CF projects
# REMOTE=blessed
# REPLACE_WHAT="<version>16-RC01</version>"
# REPLACE_BY="<version>16</version>"
# COMMIT_MSG="RELEASE-597 : Use cf-parent 16"

# PLF projects (without *-distribution)
# REMOTE=blessed
# REPLACE_WHAT="<version>17-RC01</version>"
# REPLACE_BY="<version>17</version>"
# COMMIT_MSG="RELEASE-597: Upgrade maven-parent-pom 17-RC01 -> 17"

# PLF *-distribution projects
# REMOTE=origin
# REPLACE_WHAT="<version>17-RC01</version>"
# REPLACE_BY="<version>17</version>"
# COMMIT_MSG="RELEASE-597: Upgrade maven-parent-pom 17-RC01 -> 17"

# Add-ons projects
# REMOTE=blessed
# REPLACE_WHAT="<version>8-RC01</version>"
# REPLACE_BY="<version>8</version>"
# COMMIT_MSG="RELEASE-597 : Upgrade addons-parent-pom 8-RC01 -> 8"

SCRIPTDIR=$(cd $(dirname "$0"); pwd)

function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  echo "= project: $1"
  echo "================================================================================"
  pushd $1
  git remote update
  if [ $(git rev-parse --verify develop) ]; then
    git co develop
  else
    git co -b develop origin/develop
  fi
  git pullr --prune
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
  pause "(project: $1) Press [Enter] key to continue... We will commit with message : $COMMIT_MSG"
  git commit -m "$COMMIT_MSG" -a || true
  # git push $REMOTE

  popd
}

# CF projects
 updateProject kernel                                stable/5.0.x
 updateProject core                                  stable/5.0.x
 updateProject ws                                    stable/5.0.x
 updateProject jcr                                   stable/5.0.x

# PLF projects
# updateProject docs-style                            stable/5.0.x
# updateProject platform-ui                           stable/5.0.x
# updateProject enterprise-skin                       stable/5.0.x
# updateProject commons                               stable/5.0.x
# updateProject social                                stable/5.0.x
# updateProject ecms                                  stable/5.0.x
# updateProject wiki                                  stable/5.0.x
# updateProject forum                                 stable/5.0.x
# updateProject calendar                              stable/5.0.x
# updateProject integration                           stable/5.0.x
# updateProject platform                              stable/5.0.x
# updateProject platform-public-distributions         stable/5.0.x
# updateProject platform-private-distributions        stable/5.0.x
# updateProject platform-private-trial-distributions  stable/5.0.x


# updateProject answers                               stable/2.0.x
# updateProject cas-addon                             stable/2.0.x
# updateProject chat-application                      stable/2.0.x
# updateProject cmis-addon                            stable/5.0.x
# updateProject exo-es-embedded                       stable/2.0.x
# updateProject openam-addon                          stable/2.0.x
# updateProject remote-edit                           stable/2.0.x
# updateProject saml2-addon                           stable/2.0.x
# updateProject spnego-addon                          stable/2.0.x
# updateProject task                                  stable/2.0.x
# updateProject wcm-template-pack                     stable/2.0.x
# updateProject web-conferencing                      stable/1.1.x