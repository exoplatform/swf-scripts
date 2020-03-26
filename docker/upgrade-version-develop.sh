#!/bin/bash -eu

function print_usage() {
  echo "$0 [-b] [-p] -j <JIRA_ISSUE> -v <PLF_VERSION>"
  echo "example: ./$0 -j RELEASE-1112 -v 5.3.0-M20"
  echo "-v <version> : the new PLF to use"
  echo "-j <JIRA_ID> : The jira id to add on the commit message"
  echo "-b : upgrade from the stable branch matching stable version"
  echo "-p : Push changes, nothing will be pushed if this option is not specified"
  exit 1
}

function user_validation() {
  local message=$*

  read -p "$message (Y/n) ? " response

  if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
    if [ -n "${response}" ]; then
      echo "Aborted"
      exit 1
    fi
  fi
}

STABLE_BRANCH=false
PUSH=false
while getopts "bpj:v:" opt; do
  case $opt in
  b)
    STABLE_BRANCH=true
    ;;
  p)
    printf "\e[1;33mWARN %s\e[m\n" "Push will be activated"
    PUSH=true
    ;;
  j)
    RELEASE_ISSUE="${OPTARG}"
    ;;
  v)
    EXO_VERSION="${OPTARG}"
    ;;
  *)
    echo "Invalid option "
    ;;
  esac
done

set +u
if [ -z "${RELEASE_ISSUE}" ] || [ -z "${EXO_VERSION}" ]; then
  print_usage
fi
set -u

MAJOR_VERSION=$(echo "${EXO_VERSION}" | awk -F '.' '{print $1}')
MINOR_VERSION=$(echo "${EXO_VERSION}" | awk -F '.' '{print $2}')
FIX_VERSION=$(echo "${EXO_VERSION}" | awk -F '.' '{print $3}')

CHAT_MAJOR_VERSION=$((${MAJOR_VERSION} - 3))

CHAT_VERSION="${CHAT_MAJOR_VERSION}.${MINOR_VERSION}.${FIX_VERSION}"

PROJECTS=""

# no community version for >= 6.0 and fix versions
if [ ${MAJOR_VERSION} -ge 6 ] || [ ${STABLE_BRANCH} == "true" ] && [ "${FIX_VERSION:0:1}" -gt 0 ]; then
  PROJECTS="exo-chat-server exo exo-trial"
else
  PROJECTS="exo-chat-server exo exo-trial exo-community"
fi

printf "\e[1;33mWARN %s\e[m\n" "Docker project to build : ${PROJECTS}"
user_validation Continue

function compute_stable_branch() {
  local project=$1

  case $project in
  exo-chat-server)
    #stable/5.3.x
    branch="stable/${CHAT_MAJOR_VERSION}.${MINOR_VERSION}.x"
    ;;
  exo | exo-trial)
    # 5.3.x
    branch="${MAJOR_VERSION}.${MINOR_VERSION}.x"
    ;;
  # exo-trial)
  #   # 5.3.x
  #   branch="${MAJOR_VERSION}.${MINOR_VERSION}.x"
  #   ;;
  exo-community)
    # 5.3
    branch="${MAJOR_VERSION}.${MINOR_VERSION}"
    ;;
  *)
    echo "[Error] Branch computation not defined for ${project}" >/dev/stderr
    exit 1
    ;;
  esac
  echo "${branch}"
}

function checkout_branch() {
  local project=$1
  local stable=$2

  local branch=""
  if $stable; then
    branch="$(compute_stable_branch ${project})"
  else
    branch="master"
  fi

  git reset --hard HEAD
  git checkout "$branch"
  git fetch
  git reset --hard origin/$branch
}

function merge_and_push_branch() {
  local project=$1
  local stable=$2

  if $stable; then
    branch="$(compute_stable_branch ${project})"

    if $PUSH; then
      user_validation "Ready to push branch ${branch}"
      git push origin "${branch}"
    else
      printf "\e[1;33mWARN %s\e[m\n" "Push disable : |git push origin \"${branch}\"|"
    fi
  else
    printf "\e[1;33mINFO %s\e[m\n" "Merging develop branch..."

    git checkout develop
    git reset --hard origin/develop
    git merge master

    if $PUSH; then
      git push origin master && git push origin develop
    else
      user_validation "Ready to push branch master"
      printf "\e[1;33mWARN %s\e[m\n" "Push disable : |git push origin master && git push origin develop|"
    fi
  fi

  if [ "${project}" == "exo-chat-server" ]; then
    TAG="${CHAT_VERSION}_0"
    printf "\e[1;33mINFO %s\e[m\n" "Creating version tag ${TAG}..."
    git tag --force "${TAG}"
    if $PUSH; then
      user_validation "Ready to push chat-server tag |${TAG}|"
      git push origin "${TAG}"
    else
      printf "\e[1;33mWARN %s\e[m\n" "Push disable : |git push origin \"${TAG}\"|"
    fi
  fi

}

printf "\e[1;33mWARN %s\e[m\n" "Upgration eXo version to ${EXO_VERSION} and chat application to ${CHAT_VERSION} (from stable: ${STABLE_BRANCH})"
user_validation Continue

for project in ${PROJECTS}; do
  echo "Upgrading project $project"

  if [ ! -d "$project" ]; then
    printf "\e[1;35mERROR %s\e[m\n" "Directory $project not found"
    echo "Please execute this script from a directory containing the docker images projects"
    exit 1
  fi

  pushd "$project"

  checkout_branch "${project}" ${STABLE_BRANCH}

  printf "\e[1;33mINFO %s\e[m\n" "Upgrading versions..."

  sed -E -e "s/^ENV[ ]+EXO_VERSION.*/ENV EXO_VERSION     ${EXO_VERSION}/" \
    -e "s/^ARG[ ]+EXO_VERSION=.*/ARG EXO_VERSION=${EXO_VERSION}/" \
    -e "s/^ENV[ ]+CHAT_VERSION[ ]+.*/ENV CHAT_VERSION    ${CHAT_VERSION}/" \
    -e "s/^ARG[ ]+CHAT_VERSION=.*/ARG CHAT_VERSION=${CHAT_VERSION}/" \
    -e "s/^ARG[ ]+CHAT_SERVER_VERSION=.*/ARG CHAT_SERVER_VERSION=${CHAT_VERSION}/" Dockerfile >Dockerfile.tmp
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

    merge_and_push_branch "${project}" "${STABLE_BRANCH}"
  fi

  popd
done
