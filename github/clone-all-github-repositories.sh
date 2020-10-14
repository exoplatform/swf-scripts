#!/bin/bash -eu                                                     

SCRIPT_NAME="${0##*/}"
SCRIPT_DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ "$#" != "3" ]; then
  echo "Usage: clone-all-github-repositories.sh <TARGET_DIR> <GITHUB_LOGIN> <GITHUB_TOKEN>"
  exit 1
fi

export TARGET_DIR=$1
export GITHUB_LOGIN=$2
export GITHUB_TOKEN=$3

[ "$(ls -A $TARGET_DIR)" ] && echo "TARGET_DIR ($TARGET_DIR) exists and is not empty. STOP." && exit 1 

mkdir -p $TARGET_DIR

# Clone all repositories from a GitHub organization
# $1 : The organization name
# $2 : The page number  (there are 100 entries per page)
function clone {
  curl -H "Authorization: token $GITHUB_TOKEN" -s "https://api.github.com/orgs/$1/repos?page=$2&per_page=100" | ruby -rubygems ${SCRIPT_DIR}/clone-github-orga-repos.rb
}

# Clone all exodev repositories and add blessed remotes
# $2 : The page number  (there are 100 entries per page)
function cloneDev {
	export WORKSPACE=$TARGET_DIR/exodev
	mkdir -p $WORKSPACE
  ruby -rubygems ${SCRIPT_DIR}/clone-exo-dev-with-blessed.rb
}

pushd .
cd $TARGET_DIR
# Engineering repos + corporate stuffs
cloneDev 1
clone exoplatform 1
clone exoplatform 2
# Add-ons
clone exo-addons 1
# Samples
clone exo-samples 1
# Others OSS projects
clone crashub 1
clone juzu 1
# ITOP
clone exo-docker 1
clone exo-puppet 1
# Codefest
clone exo-codefest 1
popd
exit 0;
