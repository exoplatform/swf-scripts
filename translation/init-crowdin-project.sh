#!/bin/bash -eu
# Script to init a new Crowdin project (mainly used to init maintenance project)
# Copy the translations from develop to the stable project
# To launch on blessed repositories
# Requirements:
# * Crowdin project must be created, and configured with the right languages
# Usage:
# * init-crowdin-project.sh <crowdin_project_name> <crowdin_project_key>


# Stable versions
PLF_VERSION=6.1.x
CHAT_ADDON_VERSION=3.1.x
NEWS_VERSION=2.1.x
TASK_ADDON_VERSION=3.1.x
WEB_CONFERENCING_ADDON_VERSION=2.1.x
PUSH_NOTIFICATIONS_ADDON_VERSION=2.1.x
WALLET_ADDON_VERSION=2.1.x
KUDOS_ADDON_VERSION=2.1.x
PERKSTORE_ADDON_VERSION=2.1.x
GAMIFICATION_VERSION=2.1.x
ONLYOFFICE_VERSION=2.1.x
APPCENTER_VERSION=2.1.x
DIGITAL_WORKPLACE_VERSION=1.1.x
MEEDS_VERSION=1.1.x
AGENDA_VERSION=1.0.x
JITSI_VERSION=1.0.x

CROWDIN_PROJECT_NAME=$1
CROWDIN_PROJECT_KEY=$2
LANGUAGES=en,ar,az,ca,ceb,cs,nl,fr,de,el,it,ja,fa,fil,fi,hi,hu,id,kab,ko,lt,ms,no,pcm,pl,pt-BR,pt-PT,ro,ru,sk,sl,sv-SE,tl,th,ut-IN,zh-CN,zh-TW,es-ES,tr,uk,vi

CROWDIN_MAVEN_PLUGIN_VERSION=1.2.x-SNAPSHOT

##
# Init translations in Crowdin for one project
# Arguments:
#   1: git repository (for example exoplatform/calendar)
#   2: git branch (for example stable/4.4.x) 
#
function initTranslation() {
  local gitRepo=$1
  local gitBranch=$2
  echo "############################################################################"
  echo "# Project $gitRepo - branch $gitBranch"
  echo "############################################################################"
  echo "Clone git repo exoplatform/$project - branch $gitBranch"
  pushd $project
  /usr/bin/git branch ${gitBranch} origin/${gitBranch} && git checkout ${gitBranch}
  /usr/bin/git checkout ${gitBranch} && git reset --hard origin/${gitBranch}
  echo "Upload translations of repo $gitRepo in Crowdin"
  mvn clean
  mvn org.exoplatform.translation.crowdin:crowdin-maven-plugin:${CROWDIN_MAVEN_PLUGIN_VERSION}:upload-translation -Dexo.crowdin.project.key=${CROWDIN_PROJECT_KEY} -Dexo.crowdin.project.id=${CROWDIN_PROJECT_NAME} -Dexo.crowdin.autoApprovedImported=true -Dlangs="${LANGUAGES}"
  popd
}

set -e
mkdir -p sources

projects=("gatein-portal:${PLF_VERSION}" "platform-ui:${PLF_VERSION}" "commons:${PLF_VERSION}" "ecms:${PLF_VERSION}" "social:${PLF_VERSION}" "wiki:${PLF_VERSION}" "meeds:${MEEDS_VERSION}" "platform-private-distributions:${PLF_VERSION}" "chat-application:${CHAT_ADDON_VERSION}" "push-notifications:${PUSH_NOTIFICATIONS_ADDON_VERSION}" "task:${TASK_ADDON_VERSION}" "web-conferencing:${WEB_CONFERENCING_ADDON_VERSION}" "wallet:${WALLET_ADDON_VERSION}" "kudos:${KUDOS_ADDON_VERSION}" "perk-store:${PERKSTORE_ADDON_VERSION}" "gamification:${GAMIFICATION_VERSION}" "news:${NEWS_VERSION}" "onlyoffice:${ONLYOFFICE_VERSION}" "app-center:${APPCENTER_VERSION}" "digital-workplace:${DIGITAL_WORKPLACE_VERSION}" "agenda:${AGENDA_VERSION}" "jitsi:${JITSI_VERSION}") 

for projectWithVersion in "${projects[@]}"
do
  projectInfo=(${projectWithVersion//:/ })
  project=${projectInfo[0]}
  version=${projectInfo[1]}
  gitRepo=exoplatform/$project
  gitBranch=stable/$version
  #gitBranch=develop

  initTranslation $gitRepo $gitBranch
done
