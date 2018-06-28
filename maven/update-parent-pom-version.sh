#!/usr/bin/env bash

set -ue

PUSH_CHANGES=false
while getopts "pd" option; do
	case $option in
	p)
		PUSH_CHANGES=true
		;;
	d)
		echo "Activate debug"
		set -x
		;;
	esac
done

REMOTE=origin
LOCAL_BRANCH=develop
# REMOTE_BRANCH=$REMOTE/$LOCAL_BRANCH
#REPLACE_WHAT="<org.gatein.portal.version>3.5.10.Final-SNAPSHOT</org.gatein.portal.version>"
#REPLACE_BY="<org.gatein.portal.version>3.5.11.Final-SNAPSHOT</org.gatein.portal.version>"
#COMMIT_MSG="Update Gatein 3.5.10.Final-SNAPSHOT -> 3.5.10.Final-SNAPSHOT"
REPLACE_WHAT="<version>18-M02</version>"
REPLACE_BY="<version>18-RC01</version>"
COMMIT_MSG="SWF-4382: Upgrade maven-parent-pom 18-M02 -> 18-RC01"
#REPLACE_WHAT="<version>13-SNAPSHOT</version>"
#REPLACE_BY="<version>13</version>"
#COMMIT_MSG="Use maven-parent-pom 13"

SCRIPTDIR=$(
	cd $(dirname "$0")
	pwd
)

function pause() {
	read -p "$*"
}

updateProject() {
	echo "================================================================================"
	local project=$1
	local branch=${2:-$LOCAL_BRANCH}

	local REMOTE_BRANCH=${REMOTE}/${branch}

	pushd ${project}
	git remote update

	git checkout $branch
	git reset --hard $REMOTE_BRANCH
	git branch --set-upstream-to=$REMOTE/$branch $branch

	$SCRIPTDIR/../replaceInPom.sh "$REPLACE_WHAT" "$REPLACE_BY"
	# Test if there is any changes to commit
	pwd
	CHANGED=$(git diff --name-only)
	if [ -n "${CHANGED}" ]; then
		git --no-pager diff
		pause "Press [Enter] key to continue... We will commit on project ${project} with message : $COMMIT_MSG"
		git commit -m "$COMMIT_MSG" -a || true
		if $PUSH_CHANGES; then
			git push $REMOTE
		fi
	fi
	popd
}

if $PUSH_CHANGES; then
	echo All changes will be pushed to github
	pause "Enter if ok, ctrl+c to cancel"
fi

# Supported
# updateProject juzu master

# updateProject gatein-wci
# updateProject kernel
# updateProject core
# updateProject ws
# updateProject jcr
# updateProject gatein-dep
# updateProject gatein-sso
# updateProject gatein-pc
# updateProject gatein-portal

# ## PLF
# updateProject docs-style
# updateProject platform-ui
# updateProject commons
# updateProject ecms
# updateProject social
# updateProject wiki
# updateProject forum
# updateProject calendar
# updateProject integration
# updateProject platform

# ## Addons
# updateProject addons-manager
# updateProject answers
# updateProject cas-addon
# updateProject chat-application
# updateProject cmis-addon
# # updateProject crash-addon
# updateProject exo-es-embedded

updateProject enterprise-skin
updateProject openam-addon
updateProject remote-edit
updateProject saml2-addon
updateProject spnego-addon
updateProject task
updateProject wcm-template-pack
updateProject web-conferencing
updateProject push-notifications

## Distrib
updateProject platform-public-distributions
updateProject platform-private-distributions
updateProject platform-private-trial-distributions
