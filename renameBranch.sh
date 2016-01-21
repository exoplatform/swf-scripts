#!/bin/bash -eu

BRANCH_NAME_FROM=release/1.16.4-GA
BRANCH_NAME_TO=stable/2.4.x

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}
#echo "FB source dirs = ${SWF_FB_REPOS}"

function renameBranch(){
  echo "########################################"
  echo "##### repo : $(basename $1)"
  echo "########################################"
  pushd $1
  git checkout $BRANCH_NAME_FROM
  git reset --hard origin/$BRANCH_NAME_FROM
  git pull --rebase
  # rename local branch
  git branch -m $BRANCH_NAME_FROM $BRANCH_NAME_TO
  # remove remote old branch
  git push origin --delete $BRANCH_NAME_FROM || true
  # update remote branch
  git push --set-upstream origin $BRANCH_NAME_TO
  popd
}

pushd ${SWF_FB_REPOS}
#renameBranch gatein-portal
#renameBranch docs-style
#renameBranch calendar
#renameBranch wiki
#renameBranch platform-ui
#renameBranch commons
#renameBranch social
#renameBranch ecms
#renameBranch forum
#renameBranch integration
#renameBranch platform
#renameBranch platform-public-distributions
#renameBranch platform-private-distributions
#renameBranch platform-private-trial-distributions
#renameBranch spnego-addon
#renameBranch answers
#renameBranch saml2-addon
#renameBranch openam-addon
#renameBranch josso-addon
#renameBranch cas-addon
#renameBranch remote-edit
#renameBranch chat-application
#renameBranch weemo-extension
#renameBranch acme-sample
#renameBranch cmis-addon
#renameBranch wai-sample
#renameBranch task
#renameBranch wcm-template-pack
#renameBranch ide
#renameBranch jcr-services
#renameBranch jcr
#renameBranch maven-depmgt-pom
#renameBranch kernel
#renameBranch core
#renameBranch ws
popd
exit
