#!/bin/bash -eu

ISSUE=SWF-4200
CURRENT_DEVELOP_VERSION_PREFIX=5.0.x
NEXT_DEVELOP_VERSION_PREFIX=5.1.x

CURRENT_DEVELOP_VERSION=${CURRENT_DEVELOP_VERSION_PREFIX}-SNAPSHOT
NEXT_DEVELOP_VERSION=${NEXT_DEVELOP_VERSION_PREFIX}-SNAPSHOT

JUZU_CURRENT_VERSION_PREFIX=1.2.x
JUZU_NEXT_VERSION_PREFIX=1.3.x
JUZU_CURRENT_DEVELOP_VERSION=${JUZU_CURRENT_VERSION_PREFIX}-SNAPSHOT
JUZU_NEXT_DEVELOP_VERSION=${JUZU_NEXT_VERSION_PREFIX}-SNAPSHOT

GATEIN_DEP_CURRENT_VERSION_PREFIX=1.5.x
GATEIN_DEP_NEXT_VERSION_PREFIX=1.6.x
GATEIN_DEP_CURRENT_DEVELOP_VERSION=${GATEIN_DEP_CURRENT_VERSION_PREFIX}-SNAPSHOT
GATEIN_DEP_NEXT_DEVELOP_VERSION=${GATEIN_DEP_NEXT_VERSION_PREFIX}-SNAPSHOT

MAVEN_DEPMGT_CURRENT_VERSION_PREFIX=13
MAVEN_DEPMGT_NEXT_VERSION_PREFIX=14
MAVEN_DEPMGT_CURRENT_VERSION=${MAVEN_DEPMGT_CURRENT_VERSION_PREFIX}-SNAPSHOT
MAVEN_DEPMGT_NEXT_VERSION=${MAVEN_DEPMGT_NEXT_VERSION_PREFIX}-SNAPSHOT

ADDONS_MANAGER_CURRENT_VERSION_PREFIX=1.2.x
ADDONS_MANAGER_NEXT_VERSION_PREFIX=1.3.x
ADDONS_MANAGER_CURRENT_VERSION=${ADDONS_MANAGER_CURRENT_VERSION_PREFIX}-SNAPSHOT
ADDONS_MANAGER_NEXT_VERSION=${ADDONS_MANAGER_NEXT_VERSION_PREFIX}-SNAPSHOT

ANSWERS_CURRENT_VERSION_PREFIX=1.3.x
ANSWERS_NEXT_VERSION_PREFIX=1.4.x
ANSWERS_CURRENT_VERSION=${ANSWERS_CURRENT_VERSION_PREFIX}-SNAPSHOT
ANSWERS_NEXT_VERSION=${ANSWERS_NEXT_VERSION_PREFIX}-SNAPSHOT

CAS_CURRENT_VERSION_PREFIX=1.3.x
CAS_NEXT_VERSION_PREFIX=1.4.x
CAS_CURRENT_VERSION=${CAS_CURRENT_VERSION_PREFIX}-SNAPSHOT
CAS_NEXT_VERSION=${CAS_NEXT_VERSION_PREFIX}-SNAPSHOT

CHAT_APPLICATION_CURRENT_VERSION_PREFIX=1.6.x
CHAT_APPLICATION_NEXT_VERSION_PREFIX=1.7.x
CHAT_APPLICATION_CURRENT_VERSION=${CHAT_APPLICATION_CURRENT_VERSION_PREFIX}-SNAPSHOT
CHAT_APPLICATION_NEXT_VERSION=${CHAT_APPLICATION_NEXT_VERSION_PREFIX}-SNAPSHOT

ES_EMBEDDED_CURRENT_VERSION_PREFIX=2.0.x
ES_EMBEDDED_NEXT_VERSION_PREFIX=2.1.x
ES_EMBEDDED_CURRENT_VERSION=${ES_EMBEDDED_CURRENT_VERSION_PREFIX}-SNAPSHOT
ES_EMBEDDED_NEXT_VERSION=${ES_EMBEDDED_NEXT_VERSION_PREFIX}-SNAPSHOT

OPENAM_CURRENT_VERSION_PREFIX=1.3.x
OPENAM_NEXT_VERSION_PREFIX=1.4.x
OPENAM_CURRENT_VERSION=${OPENAM_CURRENT_VERSION_PREFIX}-SNAPSHOT
OPENAM_NEXT_VERSION=${OPENAM_NEXT_VERSION_PREFIX}-SNAPSHOT

REMOTE_EDIT_CURRENT_VERSION_PREFIX=1.3.x
REMOTE_EDIT_NEXT_VERSION_PREFIX=1.4.x
REMOTE_EDIT_CURRENT_VERSION=${REMOTE_EDIT_CURRENT_VERSION_PREFIX}-SNAPSHOT
REMOTE_EDIT_NEXT_VERSION=${REMOTE_EDIT_NEXT_VERSION_PREFIX}-SNAPSHOT

SAML2_CURRENT_VERSION_PREFIX=1.3.x
SAML2_NEXT_VERSION_PREFIX=1.4.x
SAML2_CURRENT_VERSION=${SAML2_CURRENT_VERSION_PREFIX}-SNAPSHOT
SAML2_NEXT_VERSION=${SAML2_NEXT_VERSION_PREFIX}-SNAPSHOT

SPNEGO_CURRENT_VERSION_PREFIX=1.3.x
SPNEGO_NEXT_VERSION_PREFIX=1.4.x
SPNEGO_CURRENT_VERSION=${SPNEGO_CURRENT_VERSION_PREFIX}-SNAPSHOT
SPNEGO_NEXT_VERSION=${SPNEGO_NEXT_VERSION_PREFIX}-SNAPSHOT

TASK_CURRENT_VERSION_PREFIX=1.3.x
TASK_NEXT_VERSION_PREFIX=1.4.x
TASK_CURRENT_VERSION=${TASK_CURRENT_VERSION_PREFIX}-SNAPSHOT
TASK_NEXT_VERSION=${TASK_NEXT_VERSION_PREFIX}-SNAPSHOT

WCM_TEMPLATE_CURRENT_VERSION_PREFIX=1.2.x
WCM_TEMPLATE_NEXT_VERSION_PREFIX=1.3.x
WCM_TEMPLATE_CURRENT_VERSION=${WCM_TEMPLATE_CURRENT_VERSION_PREFIX}-SNAPSHOT
WCM_TEMPLATE_NEXT_VERSION=${WCM_TEMPLATE_NEXT_VERSION_PREFIX}-SNAPSHOT

WEB_CONF_CURRENT_VERSION_PREFIX=1.1.x
WEB_CONF_NEXT_VERSION_PREFIX=1.1.x
WEB_CONF_CURRENT_VERSION=${WEB_CONF_CURRENT_VERSION_PREFIX}-SNAPSHOT
WEB_CONF_NEXT_VERSION=${WEB_CONF_NEXT_VERSION_PREFIX}-SNAPSHOT


ORIGIN_BRANCH=develop
STABLE_BRANCH=stable/$CURRENT_DEVELOP_VERSION_PREFIX

SCRIPTDIR=$(cd $(dirname "$0"); pwd)
CURRENTDIR=$(pwd)

function createSBFromDevelop(){
  local repository=$1
  local devOrga=$2
  local masterBranch=${3:-$ORIGIN_BRANCH}
  local devRemoteName="origin"
  echo "########################################"
  echo "# Repository: $repository"
  echo "########################################"
  pushd $repository
  if [ "$devOrga" != "exoplatform" -a "$devOrga" != "juzu" ]; then
    echo "Testing dev repository declaration..."
    devRepoUrl="git@github.com:${devOrga}/${repository}"
    if [ $(git remote -vv | grep -c ${devRepoUrl}) -eq 0 ]; then
      echo "Installing dev repository..."
      devRemoteName="${devOrga}"
      git remote add ${devRemoteName} ${devRepoUrl}
      git fetch ${devRemoteName}
    fi
    git reset --hard ${devRemoteName}/${masterBranch}
  fi

  git remote update --prune
  git reset --hard HEAD
  git checkout ${masterBranch}
  git reset --hard origin/${masterBranch}
  git pull

  # add remote on the dev repository if needed

  #update project version on develop branch

  local stableBranch=""
  local nextVersion=""

  case $repository in
    juzu)
      stableBranch=stable/${JUZU_CURRENT_VERSION_PREFIX}
      currentVersion=${JUZU_CURRENT_DEVELOP_VERSION}
      nextVersion=${JUZU_NEXT_DEVELOP_VERSION}
    ;;
    gatein-dep)
      stableBranch=stable/${GATEIN_DEP_CURRENT_VERSION_PREFIX}
      nextVersion=${GATEIN_DEP_NEXT_DEVELOP_VERSION}
    ;;
    maven-depmgt-pom)
      stableBranch=stable/${MAVEN_DEPMGT_CURRENT_VERSION_PREFIX}
      currentVersion=${MAVEN_DEPMGT_DEVELOP_VERSION}
      nextVersion=${MAVEN_DEPMGT_NEXT_VERSION}
    ;;
    addons-manager)
      stableBranch=stable/${ADDONS_MANAGER_CURRENT_VERSION_PREFIX}
      currentVersion=${ADDONS_MANAGER_NEXT_VERSION}
      nextVersion=${ADDONS_MANAGER_NEXT_VERSION}
      ;;
    answers)
      stableBranch=stable/${ANSWERS_CURRENT_VERSION_PREFIX}
      currentVersion=${ANSWERS_CURRENT_VERSION}
      nextVersion=${ANSWERS_NEXT_VERSION}
      ;;
    cas-addon)
      stableBranch=stable/${CAS_CURRENT_VERSION_PREFIX}
      currentVersion=${CAS_CURRENT_VERSION}
      nextVersion=${CAS_NEXT_VERSION}
      ;;
    chat-application)
      stableBranch=stable/${CHAT_APPLICATION_CURRENT_VERSION_PREFIX}
      currentVersion=${CHAT_APPLICATION_CURRENT_VERSION}
      nextVersion=${CHAT_APPLICATION_NEXT_VERSION}
      ;;
    exo-es-embedded)
      stableBranch=stable/${ES_EMBEDDED_CURRENT_VERSION_PREFIX}
      currentVersion=${ES_EMBEDDED_CURRENT_VERSION}
      nextVersion=${ES_EMBEDDED_NEXT_VERSION}
      ;;
    openam-addon)
      stableBranch=stable/${OPENAM_CURRENT_VERSION_PREFIX}
      currentVersion=${OPENAM_CURRENT_VERSION}
      nextVersion=${OPENAM_NEXT_VERSION}
      ;;
    remote-edit)
      stableBranch=stable/${REMOTE_EDIT_CURRENT_VERSION_PREFIX}
      currentVersion=${REMOTE_EDIT_CURRENT_VERSION}
      nextVersion=${REMOTE_EDIT_NEXT_VERSION}
      ;;
    saml2-addon)
      stableBranch=stable/${SAML2_CURRENT_VERSION_PREFIX}
      currentVersion=${SAML2_CURRENT_VERSION}
      nextVersion=${SAML2_NEXT_VERSION}
      ;;
    spnego-addon)
      stableBranch=stable/${SPNEGO_CURRENT_VERSION_PREFIX}
      currentVersion=${SPNEGO_CURRENT_VERSION}
      nextVersion=${SPNEGO_NEXT_VERSION}
      ;;
    task)
      stableBranch=stable/${TASK_CURRENT_VERSION_PREFIX}
      currentVersion=${TASK_CURRENT_VERSION}
      nextVersion=${TASK_NEXT_VERSION}
      ;;
    wcm-template-pack)
      stableBranch=stable/${WCM_TEMPLATE_CURRENT_VERSION_PREFIX}
      currentVersion=${WCM_TEMPLATE_CURRENT_VERSION}
      nextVersion=${WCM_TEMPLATE_NEXT_VERSION}
      ;;
    web-conferencing)
      stableBranch=stable/${WEB_CONF_CURRENT_VERSION_PREFIX}
      currentVersion=${WEB_CONF_CURRENT_VERSION}
      nextVersion=${WEB_CONF_NEXT_VERSION}
      ;;
    *)
      stableBranch=stable/${CURRENT_DEVELOP_VERSION_PREFIX}
      currentVersion=${CURRENT_DEVELOP_VERSION}
      nextVersion=${NEXT_DEVELOP_VERSION}
    ;;
  esac
  echo "Create stable branch ${stableBranch}"
  git checkout -f -B ${stableBranch}
  # git push origin ${stableBranch}


  echo "Prepare next version ${nextVersion}"
  git checkout $masterBranch

  $SCRIPTDIR/../replaceInPom.sh "<version>${currentVersion}</version>" "<version>${nextVersion}</version>"

  $SCRIPTDIR/../replaceInPom.sh "<version>16-RC01</version>" "<version>17-SNAPSHOT</version>"
  
  $SCRIPTDIR/../replaceInPom.sh "<org.juzu.version>${JUZU_CURRENT_DEVELOP_VERSION}</org.juzu.version>" "<org.juzu.version>${JUZU_NEXT_DEVELOP_VERSION}</org.juzu.version>"
  
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.depmgt.version>${MAVEN_DEPMGT_CURRENT_VERSION}</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>${MAVEN_DEPMGT_NEXT_VERSION}</org.exoplatform.depmgt.version>"

  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.wci.version>${CURRENT_DEVELOP_VERSION}</org.exoplatform.gatein.wci.version>" "<org.exoplatform.gatein.wci.version>${NEXT_DEVELOP_VERSION}</org.exoplatform.gatein.wci.version>"

  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.kernel.version>${CURRENT_DEVELOP_VERSION}</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>${NEXT_DEVELOP_VERSION}</org.exoplatform.kernel.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.core.version>${CURRENT_DEVELOP_VERSION}</org.exoplatform.core.version>" "<org.exoplatform.core.version>${NEXT_DEVELOP_VERSION}</org.exoplatform.core.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ws.version>${CURRENT_DEVELOP_VERSION}</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>${NEXT_DEVELOP_VERSION}</org.exoplatform.ws.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.jcr.version>${CURRENT_DEVELOP_VERSION}</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>${NEXT_DEVELOP_VERSION}</org.exoplatform.jcr.version>"

  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.dep.version>$GATEIN_DEP_CURRENT_DEVELOP_VERSION</org.exoplatform.gatein.dep.version>" "<org.exoplatform.gatein.dep.version>$GATEIN_DEP_NEXT_DEVELOP_VERSION</org.exoplatform.gatein.dep.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.sso.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.gatein.sso.version>" "<org.exoplatform.gatein.sso.version>$NEXT_DEVELOP_VERSION</org.exoplatform.gatein.sso.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.pc.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.gatein.pc.version>" "<org.exoplatform.gatein.pc.version>$NEXT_DEVELOP_VERSION</org.exoplatform.gatein.pc.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.portal.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.gatein.portal.version>" "<org.exoplatform.gatein.portal.version>$NEXT_DEVELOP_VERSION</org.exoplatform.gatein.portal.version>"

  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.commons.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$NEXT_DEVELOP_VERSION</org.exoplatform.commons.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.doc.doc-style.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>$NEXT_DEVELOP_VERSION</org.exoplatform.doc.doc-style.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform-ui.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$NEXT_DEVELOP_VERSION</org.exoplatform.platform-ui.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ecms.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$NEXT_DEVELOP_VERSION</org.exoplatform.ecms.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.social.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$NEXT_DEVELOP_VERSION</org.exoplatform.social.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.forum.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$NEXT_DEVELOP_VERSION</org.exoplatform.forum.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.wiki.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$NEXT_DEVELOP_VERSION</org.exoplatform.wiki.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.calendar.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$NEXT_DEVELOP_VERSION</org.exoplatform.calendar.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.integ.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$NEXT_DEVELOP_VERSION</org.exoplatform.integ.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$NEXT_DEVELOP_VERSION</org.exoplatform.platform.version>"
  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.distributions.version>$CURRENT_DEVELOP_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$NEXT_DEVELOP_VERSION</org.exoplatform.platform.distributions.version>"

  $SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.addons-manager.version>${ADDONS_MANAGER_CURRENT_VERSION}</org.exoplatform.platform.addons-manager.version>" "<org.exoplatform.platform.addons-manager.version>${ADDONS_MANAGER_NEXT_VERSION}</org.exoplatform.platform.addons-manager.version>"
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.es.embedded.version>${ES_EMBEDDED_CURRENT_VERSION}</addon.exo.es.embedded.version>" "<addon.exo.es.embedded.version>${ES_EMBEDDED_NEXT_VERSION}</addon.exo.es.embedded.version>"

  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.remote-edit.version>${REMOTE_EDIT_CURRENT_VERSION}</addon.exo.remote-edit.version>" "<addon.exo.remote-edit.version>${REMOTE_EDIT_NEXT_VERSION}</addon.exo.remote-edit.version>"
  # < 5.0.0
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.remote.edit.version>${REMOTE_EDIT_CURRENT_VERSION}</addon.exo.remote.edit.version>" "<addon.exo.remote.edit.version>${REMOTE_EDIT_NEXT_VERSION}</addon.exo.remote.edit.version>"
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.tasks.version>${TASK_CURRENT_VERSION}</addon.exo.tasks.version>" "<addon.exo.tasks.version>${TASK_NEXT_VERSION}</addon.exo.tasks.version>"
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.web-pack.version>${WCM_TEMPLATE_CURRENT_VERSION}</addon.exo.web-pack.version>" "<addon.exo.web-pack.version>${WCM_TEMPLATE_NEXT_VERSION}</addon.exo.web-pack.version>"
  # < 5.0.0
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.web.pack.version>${WCM_TEMPLATE_CURRENT_VERSION}</addon.exo.web.pack.version>" "<addon.exo.web.pack.version>${WCM_TEMPLATE_NEXT_VERSION}</addon.exo.web.pack.version>"
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.web-conferencing.version>${WEB_CONF_CURRENT_VERSION}</addon.exo.web-conferencing.version>" "<addon.exo.web-conferencing.version>${WEB_CONF_NEXT_VERSION}</addon.exo.web-conferencing.version>"
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.enterprise-skin.version>${CURRENT_DEVELOP_VERSION}</addon.exo.enterprise-skin.version>" "<addon.exo.enterprise-skin.version>${NEXT_DEVELOP_VERSION_PREFIX}</addon.exo.enterprise-skin.version>"
  $SCRIPTDIR/../replaceInPom.sh "<addon.exo.chat.version>${CHAT_APPLICATION_CURRENT_VERSION}</addon.exo.chat.version>" "<addon.exo.chat.version>${CHAT_APPLICATION_NEXT_VERSION}</addon.exo.chat.version>"
  
  git commit -m "$ISSUE: Update projects versions to ${nextVersion}" -a
  # git push ${devRemoteName} ${masterBranch}

  popd
}

# Not yet supported
# createSBFromDevelop cf-parent
# createSBFromDevelop maven-depmgt-pom

# Supported
createSBFromDevelop juzu juzu master 

createSBFromDevelop gatein-wci exo-dev
createSBFromDevelop kernel exo-dev
createSBFromDevelop core exo-dev
createSBFromDevelop ws exo-dev
createSBFromDevelop jcr exo-dev
createSBFromDevelop gatein-dep exoplatform
createSBFromDevelop gatein-sso exo-dev
createSBFromDevelop gatein-pc exo-dev
createSBFromDevelop gatein-portal exo-dev

## PLF
createSBFromDevelop docs-style exo-dev
createSBFromDevelop platform-ui exo-dev
createSBFromDevelop commons exo-dev
createSBFromDevelop ecms exo-dev
createSBFromDevelop social exo-dev
createSBFromDevelop wiki exo-dev
createSBFromDevelop forum exo-dev
createSBFromDevelop calendar exo-dev
createSBFromDevelop integration exo-dev
createSBFromDevelop platform exodev

## Addons
createSBFromDevelop addons-manager exoplatform
createSBFromDevelop answers exo-addons
createSBFromDevelop cas-addon exo-addons
createSBFromDevelop chat-application exo-addons
createSBFromDevelop cmis-addon exo-addons
createSBFromDevelop crash-addon exo-addons
createSBFromDevelop exo-es-embedded exo-addons
createSBFromDevelop enterprise-skin exoplatform
createSBFromDevelop openam-addon exo-addons
createSBFromDevelop remote-edit exo-addons
createSBFromDevelop saml2-addon exoplatform
createSBFromDevelop spnego-addon exo-addons
createSBFromDevelop task exo-addons
createSBFromDevelop wcm-template-pack exo-addons
createSBFromDevelop web-conferencing exo-addons

## Distrib
createSBFromDevelop platform-public-distributions exoplatform
createSBFromDevelop platform-private-distributions exoplatform
createSBFromDevelop platform-private-trial-distributions exoplatform
