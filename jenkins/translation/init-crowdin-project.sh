#!/bin/bash -eu
# Script to init a new Crowdin project (mainly used to init maintenance project)
# Requirements:
# * Crowdin project must be created, and configured with the right languages
# Usage:
# * init-crowdin-project.sh <crowdin_project_name> <crowdin_project_key>

PLF_VERSION=4.4.x
CHAT_ADDON_VERSION=1.4.x
TASK_ADDON_VERSION=1.2.x

CROWDIN_PROJECT_NAME=$1
CROWDIN_PROJECT_KEY=$2
LANGUAGES=en,ar,ca,nl,fr,de,el,it,ja,fa,pl,pt-BR,ru,zh-CN,sl,es-ES,tr,uk,vi,sq

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
  pushd sources && /usr/bin/git clone git@github.com:$gitRepo.git
  cd $project && /usr/bin/git branch ${gitBranch} origin/${gitBranch} && git checkout ${gitBranch}
  echo "Upload translations of repo $gitRepo in Crowdin"
  mvn org.exoplatform.translation.crowdin:crowdin-maven-plugin:${CROWDIN_MAVEN_PLUGIN_VERSION}:upload-translation -Dexo.crowdin.project.key=${CROWDIN_PROJECT_KEY} -Dexo.crowdin.project.id=${CROWDIN_PROJECT_NAME} -Dexo.crowdin.autoApprovedImported=true -Dlangs=${LANGUAGES}
  popd
}

set -e
mkdir -p sources

projects=("gatein-portal:${PLF_VERSION}" "platform-ui:${PLF_VERSION}" "commons:${PLF_VERSION}" "ecms:${PLF_VERSION}" "social:${PLF_VERSION}" "wiki:${PLF_VERSION}" "forum:${PLF_VERSION}" "calendar:${PLF_VERSION}" "integration:${PLF_VERSION}" "platform:${PLF_VERSION}" "platform-public-distributions:${PLF_VERSION}" "platform-private-distributions:${PLF_VERSION}" "chat-application:${CHAT_ADDON_VERSION}" "task:${TASK_ADDON_VERSION}")

for projectWithVersion in "${projects[@]}"
do
  projectInfo=(${projectWithVersion//:/ })
  project=${projectInfo[0]}
  version=${projectInfo[1]}
  gitRepo=exoplatform/$project
  gitBranch=stable/$version

  initTranslation $gitRepo $gitBranch
done