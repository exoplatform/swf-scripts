#!/bin/bash -ue

BRANCH=social-rest-api
ISSUE=SWF-3312
ORIGIN_BRANCH=PoC/soc-rest-api
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=4.2.x-SNAPSHOT
TARGET_VERSION_PREFIX=4.3.x


function pause(){
   read -p "$*"
}

updateProject (){
  echo "================================================================================"
  local repo_name=$1
  printf "\e[1;33m########################################\e[m\n"
  printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
  printf "\e[1;33m########################################\e[m\n"
  pushd ${repo_name}

  # Remove all branches but the origin one
  #  git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
  printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
  git remote update --prune
  git reset --hard HEAD
  git checkout $ORIGIN_BRANCH
  git reset --hard HEAD
  git pull
  printf "\e[1;33m# %s\e[m\n" "Testing if ${TARGET_BRANCH} branch doesn't already exists and reuse it ..."
  set +e
  git checkout $TARGET_BRANCH
  if [ "$?" -ne "0" ]; then
    git checkout -b $TARGET_BRANCH
  else
    printf "\e[1;35m# %s\e[m\n" "WARNING : the ${TARGET_BRANCH} branch already exists so we reuse it (you have 5 seconds to cancel with CTRL+C) ..."
    sleep 5
  fi

  #CF
  replaceInPom.sh "<org.exoplatform.depmgt.version>10-SNAPSHOT</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>11-SNAPSHOT</org.exoplatform.depmgt.version>"
  replaceInPom.sh "<org.exoplatform.kernel.version>2.4.x-SNAPSHOT</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>2.5.1-GA</org.exoplatform.kernel.version>"
  replaceInPom.sh "<org.exoplatform.core.version>2.5.x-SNAPSHOT</org.exoplatform.core.version>" "<org.exoplatform.core.version>2.6.1-GA</org.exoplatform.core.version>"
  replaceInPom.sh "<org.exoplatform.ws.version>2.3.x-SNAPSHOT</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>2.4.1-GA</org.exoplatform.ws.version>"
  replaceInPom.sh "<org.exoplatform.jcr.version>1.15.x-SNAPSHOT</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>1.16.1-GA</org.exoplatform.jcr.version>"

  #PLF
  replaceInPom.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION_PREFIX-$2-$BRANCH-SNAPSHOT</version>" ""
  replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_VERSION_PREFIX-plfui-$BRANCH-SNAPSHOT</org.exoplatform.platform-ui.version>"
  replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_VERSION_PREFIX-commons-$BRANCH-SNAPSHOT</org.exoplatform.commons.version>"
  replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_VERSION_PREFIX-ecms-$BRANCH-SNAPSHOT</org.exoplatform.ecms.version>"
  replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_VERSION_PREFIX-soc-$BRANCH-SNAPSHOT</org.exoplatform.social.version>"
  replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_VERSION_PREFIX-forum-$BRANCH-SNAPSHOT</org.exoplatform.forum.version>"
  replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_VERSION_PREFIX-wiki-$BRANCH-SNAPSHOT</org.exoplatform.wiki.version>"
  replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_VERSION_PREFIX-cal-$BRANCH-SNAPSHOT</org.exoplatform.calendar.version>"
  replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_VERSION_PREFIX-integ-$BRANCH-SNAPSHOT</org.exoplatform.integ.version>"
  replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_VERSION_PREFIX-plf-$BRANCH-SNAPSHOT</org.exoplatform.platform.version>"
  replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_VERSION_PREFIX-pkgpub-$BRANCH-SNAPSHOT</org.exoplatform.platform.distributions.version>"

  replaceInPom.sh "<org.exoplatform.doc.doc-style.version>4.2.x-SNAPSHOT</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>4.3.x-SNAPSHOT</org.exoplatform.doc.doc-style.version>"
  replaceInPom.sh "<org.gatein.portal.version>4.2.x-PLF-SNAPSHOT</org.gatein.portal.version>" "<org.gatein.portal.version>4.3.x-PLF-SNAPSHOT</org.gatein.portal.version>"

  printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ..."
  git commit -m"$ISSUE : Create $BRANCH branch and update projects versions" -a
  git push origin $TARGET_BRANCH --set-upstream
  git checkout develop
  popd

}

updateProject social soc
