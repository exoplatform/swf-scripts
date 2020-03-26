#!/bin/bash -eu

BRANCH_TO_DELETE=feature/news2
DEFAULT_BRANCH=develop

SCRIPTDIR=$(
  cd $(dirname "$0")
  pwd
)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}
#echo "FB source dirs = ${SWF_FB_REPOS}"

function deleteGitBranch() {
  echo "########################################"
  echo "##### repo : $(basename $1)"
  echo "########################################"
  pushd $1
  git reset --hard origin/$DEFAULT_BRANCH
  git clean -df
  git checkout $DEFAULT_BRANCH

  git branch -D $BRANCH_TO_DELETE || true
  git push origin --delete $BRANCH_TO_DELETE || true
  popd
}

#pushd ${SWF_FB_REPOS}
deleteGitBranch gatein-dep
deleteGitBranch gatein-wci
deleteGitBranch kernel
deleteGitBranch core
deleteGitBranch ws
deleteGitBranch jcr
deleteGitBranch gatein-pc
deleteGitBranch gatein-sso
deleteGitBranch gatein-portal
deleteGitBranch maven-depmgt-pom
deleteGitBranch docs-style
deleteGitBranch platform-ui
deleteGitBranch commons
deleteGitBranch social
deleteGitBranch ecms
deleteGitBranch wiki
deleteGitBranch forum
deleteGitBranch calendar
deleteGitBranch integration
deleteGitBranch platform
deleteGitBranch addons-manager
# deleteGitBranch answers # Not after 5.1
deleteGitBranch cas-addon
deleteGitBranch chat-application
deleteGitBranch cmis-addon
deleteGitBranch enterprise-skin
deleteGitBranch exo-es-embedded
deleteGitBranch kudos
deleteGitBranch lecko
deleteGitBranch openam-addon
deleteGitBranch perk-store
deleteGitBranch push-notifications
deleteGitBranch remote-edit
deleteGitBranch saml2-addon
deleteGitBranch spnego-addon
deleteGitBranch task
deleteGitBranch wallet
deleteGitBranch wcm-template-pack
deleteGitBranch web-conferencing

deleteGitBranch platform-public-distributions
deleteGitBranch platform-private-distributions
# Not adter 5.2
# deleteGitBranch platform-private-trial-distributions

#popd
exit
