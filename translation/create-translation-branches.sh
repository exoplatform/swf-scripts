#!/bin/bash -eu

# Script to create Translation branches on exodev:
# * X-x.x-translation
VERSION=6.1.x-translation
ORIGIN_BRANCH=develop
TARGET_BRANCH=integration/$VERSION

SCRIPTDIR=$(
  cd $(dirname "$0")
  pwd
)
CURRENTDIR=$(pwd)

SWF_TB_REPOS=${SWF_TB_REPOS:-$CURRENTDIR}

function createTranslationBranche() {
  local repo_name=$1
  printf "\e[1;33m########################################\e[m\n"
  printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
  printf "\e[1;33m########################################\e[m\n"
  pushd ${repo_name}

  printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
  git remote update --prune
  git reset --hard HEAD
  git checkout $ORIGIN_BRANCH
  git reset --hard HEAD
  git pull
  printf "\e[1;33m# %s\e[m\n" "Testing if ${TARGET_BRANCH} branch doesn't already exists and reuse it ..."
  GIT_OPT=""

  set +e
  git checkout $TARGET_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $TARGET_BRANCH
  else
    printf "\e[1;35m# %s\e[m\n" "WARNING : the ${TARGET_BRANCH} branch already exists so we reuse it (you have 5 seconds to cancel with CTRL+C) ..."
    # sleep 5
    git reset --hard $ORIGIN_BRANCH
    GIT_OPT="--force"
  fi
  set -e
  git push ${GIT_OPT} origin $TARGET_BRANCH --set-upstream
  git checkout develop
  popd
}

pushd ${SWF_TB_REPOS}

createTranslationBranche gatein-portal
createTranslationBranche platform-ui
createTranslationBranche commons
createTranslationBranche social
createTranslationBranche ecms
createTranslationBranche calendar
createTranslationBranche wiki
createTranslationBranche forum
createTranslationBranche news
createTranslationBranche task
createTranslationBranche chat-application
createTranslationBranche digital-workplace
createTranslationBranche legacy-intranet
createTranslationBranche lecko
createTranslationBranche web-conferencing
createTranslationBranche onlyoffice
createTranslationBranche app-center
createTranslationBranche gamification
createTranslationBranche kudos
createTranslationBranche perk-store
createTranslationBranche push-notifications
createTranslationBranche wallet
createTranslationBranche meeds
createTranslationBranche platform-private-distributions

popd
