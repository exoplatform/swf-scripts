#!/bin/bash -eu
# Script to init a new Crowdin project (mainly used to init maintenance project)
# Requirements:
# * Crowdin project must be created, and configured with the right languages
# Usage:
# * init-crowdin-project.sh <crowdin_project_name> <crowdin_project_key>

VERSION=4.4.x
GIT_SOURCE_BRANCH=stable/$VERSION
CROWDIN_PROJECT_NAME=$1
CROWDIN_PROJECT_KEY=$2
LANGUAGES=en,ar,ca,nl,fr,de,el,it,ja,fa,pl,pt-BR,ru,zh-CN,sl,es-ES,tr,uk,vi,sq

CROWDIN_MAVEN_PLUGIN_VERSION=1.2.x-SNAPSHOT

set -e
mkdir -p sources
arr=("gatein-portal" "platform-ui" "commons" "ecms" "social" "wiki" "forum" "calendar" "integration" "platform" "platform-public-distributions" "platform-private-distributions")
for project in "${arr[@]}"
do
  echo "Clone git repo $project of origin repository"
  pushd sources && /usr/bin/git clone git@github.com:exoplatform/$project.git
  cd $project && /usr/bin/git branch ${GIT_SOURCE_BRANCH} origin/${GIT_SOURCE_BRANCH} && git checkout ${GIT_SOURCE_BRANCH}
  echo "Upload translations of repo $project in Crowdin"
  mvn org.exoplatform.translation.crowdin:crowdin-maven-plugin:${CROWDIN_MAVEN_PLUGIN_VERSION}:upload-translation -Dexo.crowdin.project.key=${CROWDIN_PROJECT_KEY} -Dexo.crowdin.project.id=${CROWDIN_PROJECT_NAME} -Dexo.crowdin.autoApprovedImported=true -Dlangs=${LANGUAGES}
  popd
done
