#!/bin/bash -eu
# git commit -a -m "PLF-6503: Update SNAPSHOTS dependencies for 4.3.0-RC1-1"
BRANCH=4.3.x
ISSUE=PLF-6503

# Versions to find
ORIGIN_VERSION=4.3.x-RC-SNAPSHOT
ORIGIN_GATEIN_VERSION=4.3.x-PLF-RC-SNAPSHOT
ORIGIN_DEPGMT_VERSION=11-RC-SNAPSHOT
# And, for release branch, replace with:
TARGET_PLF_VERSION=4.3.0-RC1-1
TARGET_GATEIN_VERSION=4.3.0-RC1-1-PLF
TARGET_DEPGMT_VERSION=11-RC1-1

# And, for next dev version, replace with:
NEXT_DEVELOP_PLF_VERSION=4.3.x-SNAPSHOT
NEXT_DEVELOP_GATEIN_VERSION=4.3.x-PLF-SNAPSHOT
NEXT_DEVELOP_DEPGMT_VERSION=11-SNAPSHOT


function replaceDeps(){
  echo "########################################"
  echo "# Replace deps: $1"
  echo "########################################"
  pushd $1


  set -e

    # PLF Projects
    replaceInPom.sh "<org.exoplatform.doc.doc-style.version>$ORIGIN_VERSION</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>$TARGET_PLF_VERSION</org.exoplatform.doc.doc-style.version>"
    replaceInPom.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_PLF_VERSION</org.exoplatform.platform-ui.version>"
    replaceInPom.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_PLF_VERSION</org.exoplatform.commons.version>"
    replaceInPom.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_PLF_VERSION</org.exoplatform.ecms.version>"
    replaceInPom.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_PLF_VERSION</org.exoplatform.social.version>"
    replaceInPom.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_PLF_VERSION</org.exoplatform.forum.version>"
    replaceInPom.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_PLF_VERSION</org.exoplatform.wiki.version>"
    replaceInPom.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_PLF_VERSION</org.exoplatform.calendar.version>"
    replaceInPom.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_PLF_VERSION</org.exoplatform.integ.version>"
    replaceInPom.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_PLF_VERSION</org.exoplatform.platform.version>"
    replaceInPom.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_PLF_VERSION</org.exoplatform.platform.distributions.version>"

    # GateIn
    replaceInPom.sh "<org.gatein.portal.version>$ORIGIN_GATEIN_VERSION</org.gatein.portal.version>" "<org.gatein.portal.version>$TARGET_GATEIN_VERSION</org.gatein.portal.version>"
    # POM depgmt
    replaceInPom.sh "<org.exoplatform.depmgt.version>$ORIGIN_DEPGMT_VERSION</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>$TARGET_DEPGMT_VERSION</org.exoplatform.depmgt.version>"

    ## Commit and Push Release Branch and update versions
    printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $ branch to origin ..."
    git commit -m"$ISSUE: Update SNAPSHOTS dependencies for 4.3.0-RC1-1" -a
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
