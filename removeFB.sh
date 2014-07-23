#!/bin/bash -eu

BRANCH=feature/4.1.x-translation

function deleteFB(){
  pushd $1
  git checkout master
  git branch -D $BRANCH || true
  git push origin --delete $BRANCH || true
  popd
}


deleteFB platform-ui
deleteFB commons
deleteFB social
deleteFB ecms
deleteFB wiki
deleteFB forum
deleteFB calendar
deleteFB integration
deleteFB platform
deleteFB platform-public-distributions
deleteFB platform-private-distributions
