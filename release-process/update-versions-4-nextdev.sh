#!/bin/bash -eu

ISSUE=PLF-6503

################## RELEASE BRANCH INFOS ######################
RELEASE_VERSION=4.3.0-RC1-1
RELEASE_BRANCH=release/4.3.x
# Versions to find
RELEASE_BRANCH_ORIGIN_VERSION=4.3.x-SNAPSHOT
RELEASE_BRANCH_ORIGIN_GATEIN_VERSION=4.3.x-PLF-SNAPSHOT
RELEASE_BRANCH_ORIGIN_DEPGMT_VERSION=11-SNAPSHOT
# And, for release branch, replace with:
RELEASE_BRANCH_TARGET_PLF_VERSION=4.3.0-RC1-1
RELEASE_BRANCH_TARGET_GATEIN_VERSION=4.3.0-RC1-1-PLF
RELEASE_BRANCH_TARGET_DEPGMT_VERSION=11-RC1-1
# And, for next dev version, replace with:
RELEASE_NEXT_DEVELOP_PLF_VERSION=4.3.x-SNAPSHOT
RELEASE_NEXT_DEVELOP_GATEIN_VERSION=4.3.x-PLF-SNAPSHOT
RELEASE_NEXT_DEVELOP_DEPGMT_VERSION=11-SNAPSHOT
#######################################################

################ DEVELOP BRANCH INFOS #################
DEVELOP_BRANCH=develop
DEVELOP_BRANCH_NEXT_PLF_VERSION=4.4.x-SNAPSHOT
DEVELOP_BRANCH_NEXT_GATEIN_VERSION=4.4.x-PLF-SNAPSHOT
DEVELOP_BRANCH_NEXT_DEPGMT_VERSION=12-SNAPSHOT

# Addons
CHAT_PROPERTY="addon.exo.chat.version"
REMOTE_EDIT_PROPERTY="addon.exo.remote.edit.version"
SITE_TEMPLATE_PROPERTY="addon.exo.site.templates.version"
TASKS_PROPERTY="addon.exo.tasks.version"
VIDEO_CALLS_PROPERTY="addon.exo.video.calls.version"
ACME_SAMPLE_PROPERTY="addon.exo.acme.sample.version"
ANSWERS_PROPERTY="addon.exo.answers.version"
CAS_PROPERTY="addon.exo.cas.version"
CMIS_PROPERTY="addon.exo.cmis.version"
IDE_PROPERTY="addon.exo.ide.version"
JOSSO_PROPERTY="addon.exo.josso.version"
JOSSO_PROPERTY="addon.exo.josso181.version"
OPENAM_PROPERTY="addon.exo.openam.version"
SAML_PROPERTY="addon.exo.saml.version"
SPNEGO_PROPERTY="addon.exo.spnego.version"
WAI_SAMPLE_PROPERTY="addon.exo.wai.sample.version"

# Projects
PLF_DIST_PROPERTY="org.exoplatform.platform.distributions.version"
PLATFORM_PROPERTY="org.exoplatform.platform.version"
INTEG_PROPERTY="org.exoplatform.integ.version"
CALENDAR_PROPERTY="org.exoplatform.calendar.version"
FORUM_PROPERTY="org.exoplatform.forum.version"
WIKI_PROPERTY="org.exoplatform.wiki.version"
SOCIAL_PROPERTY="org.exoplatform.social.version"
ECMS_PROPERTY="org.exoplatform.ecms.version"
COMMONS_PROPERTY="org.exoplatform.commons.version"
PLF_UI_PROPERTY="org.exoplatform.platform-ui.version"
DOC_STYLE_PROPERTY="org.exoplatform.doc.doc-style.version"
POM_DEPGMT_PROPERTY="org.exoplatform.depmgt.version"
JUZU_PROPERTY="org.juzu.version"
GATEIN_PORTAL_PROPERTY="org.gatein.portal.version"
JCR_SERVICES_PROPERTY="org.exoplatform.jcr-services.version"
JCR_PROPERTY="org.exoplatform.jcr.version"
WS_PROPERTY="org.exoplatform.ws.version"
CORE_PROPERTY="org.exoplatform.core.version"
KERNEL_PROPERTY="org.exoplatform.kernel.version"


function replaceDeps(){
  echo "########################################"
  echo "# Replace deps: $1"
  echo "########################################"
  pushd $1

  set -e

  # eXo Depgmt
  mvn versions:update-property -Dproperty=$POM_DEPGMT_PROPERTY -DnewVersion=$RELEASE_NEXT_DEVELOP_DEPGMT_VERSION -DallowSnapshots=true

  # PLF Versions
  mvn versions:update-property -Dproperty=$POM_DEPGMT_PROPERTY -DnewVersion=$DEVELOP_BRANCH_NEXT_PLF_VERSION -DallowSnapshots=true

  


      ## Commit and Push Release Branch and update versions
    printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $ branch to origin ..."
    git commit -m "$ISSUE: Update SNAPSHOTS dependencies for next development" -a
    git push

  popd
}


createSB platform-ui
createSB commons
createSB social
createSB ecms
createSB wiki
createSB forum
createSB calendar
createSB integration
createSB platform
createSB platform-public-distributions
createSB platform-private-distributions
