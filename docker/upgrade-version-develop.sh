#!/bin/bash -eu

function print_usage() {
  echo "$0 <JIRA_ISSUE> <PLF_VERSION>"
  echo "example: ./$0 RELEASE-1112 5.3.0-M20"
  exit 1
}

function user_validation() {
  local message=$*

  read -p "$message (Y/n) ? " response

  if [ "$response" != "y" -a "$response" != "Y" ]; then
    if [ -n "${response}" ]; then
      echo "Aborted"
      exit 1
    fi
  fi
}

SED_INLINE="-i"

if [ $# -ne 2 ]; then
  print_usage
fi

RELEASE_ISSUE=$1
EXO_VERSION=$2

MAJOR_VERSION=$(echo "${EXO_VERSION}" | awk -F '.' '{print $1}')
MINOR_VERSION=$(echo "${EXO_VERSION}" | awk -F '.' '{print $2}')
FIX_VERSION=$(echo "${EXO_VERSION}" | awk -F '.' '{print $3}')

CHAT_MAJOR_VERSION=$(( ${MAJOR_VERSION} - 3 ))

CHAT_VERSION="${CHAT_MAJOR_VERSION}.${MINOR_VERSION}.${FIX_VERSION}"

PROJECTS="exo-chat-server exo exo-community exo-trial"

printf "\e[1;33mWARN %s\e[m\n" "Upgration eXo version to ${EXO_VERSION} and chat application to ${CHAT_VERSION}"
user_validation Continue

for project in ${PROJECTS}
do
  echo Upgrading project $project

  if [ ! -d "$project" ]; then
    printf "\e[1;35mERROR %s\e[m\n" "Directory $project not found"
    echo "Please execute this script from a directory containing the docker images projects"
    exit 1
  fi

  pushd $project
  git reset --hard HEAD
  git checkout master
  git pull
  git reset --hard origin/master

  printf "\e[1;33mINFO %s\e[m\n" "Upgrading versions..."

  sed -E -e "s/^ENV[ ]+EXO_VERSION.*/ENV EXO_VERSION     ${EXO_VERSION}/" \
    -e "s/^ARG[ ]+EXO_VERSION=.*/ARG EXO_VERSION=${EXO_VERSION}/" \
    -e "s/^ENV[ ]+CHAT_VERSION[ ]+.*/ENV CHAT_VERSION    ${CHAT_VERSION}/" \
    -e "s/^ARG[ ]+CHAT_VERSION=.*/ARG CHAT_VERSION=${CHAT_VERSION}/" \
    -e "s/^ARG[ ]+CHAT_SERVER_VERSION=.*/ARG CHAT_SERVER_VERSION=${CHAT_VERSION}/" Dockerfile > Dockerfile.tmp
  mv -f Dockerfile.tmp Dockerfile

  git --no-pager diff

  if [ $(git diff Dockerfile | wc -l) -eq 0 ]; then
    printf "\e[1;33mINFO %s\e[m\n" "No changes detected"
    user_validation Continue
  else 
    COMMIT_MSG="${RELEASE_ISSUE} Release PLF ${EXO_VERSION}"
    printf "\e[1;33mINFO %s\e[m\n" "Commit message will be :"
    echo "${COMMIT_MSG}"

    user_validation Continue

    git add Dockerfile
    git commit -m "${COMMIT_MSG}"

    printf "\e[1;33mINFO %s\e[m\n" "Merging develop branch..."

    git checkout develop
    git reset --hard origin/develop
    git merge master

    user_validation "Ready to push"
    git push origin master && git push origin develop

    if [ "${project}" == "exo-chat-server" ]; then
      TAG="${CHAT_VERSION}_0"
      printf "\e[1;33mINFO %s\e[m\n" "Creating version tag ${TAG}..."
      git tag "${TAG}"
      git push origin "${TAG}"
    fi
  fi

  popd
done
