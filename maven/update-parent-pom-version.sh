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
	*)
		echo "unsupported option ${option}"
		exit 1
		;;
	esac
done

REMOTE=origin
LOCAL_BRANCH=develop

PREVIOUS_VERSION=21-M02
NEXT_VERSION=21-RC01
ISSUE=TASK-26260
PROJECT=maven-parent-pom

REPLACE_WHAT="<version>${PREVIOUS_VERSION}</version>"
REPLACE_BY="<version>${NEXT_VERSION}</version>"
COMMIT_MSG="${ISSUE}: Upgrade ${PROJECT} ${PREVIOUS_VERSION} -> ${NEXT_VERSION}"

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
	CHANGED=$(git diff -w)
	if [ -n "${CHANGED}" ]; then
		git --no-pager diff
		pause "Press [Enter] key to continue... We will commit on project ${project} with message : $COMMIT_MSG"
		git commit -m "$COMMIT_MSG" -a || true
		if $PUSH_CHANGES; then
			git push $REMOTE $branch
		else
			echo
			echo "===== push disabled : issued command will be |git push $REMOTE $branch|"
			echo

		fi
	fi
	popd
}

if $PUSH_CHANGES; then
	echo All changes will be pushed to github
	pause "Enter if ok, ctrl+c to cancel"
fi

# Supported
updateProject addons-parent-pom develop
updateProject maven-depmgt-pom develop
# updateProject juzu master # # stable/1.2.x

updateProject gatein-wci develop
updateProject kernel develop
updateProject core develop
updateProject ws develop
updateProject jcr develop
updateProject gatein-dep develop
updateProject gatein-sso develop
updateProject gatein-pc develop
updateProject gatein-portal develop

## PLF
#updateProject docs-style develop
updateProject platform-ui develop
updateProject commons develop
updateProject ecms develop
updateProject social develop
updateProject wiki develop
updateProject forum develop
updateProject calendar develop
#updateProject integration develop
updateProject platform develop

## Addons
updateProject addons-manager # stable/1.5.x
# Not supported starting from 5.2.0
# updateProject answers # stable/2.1.x
updateProject cas-addon develop
updateProject chat-application develop
updateProject cmis-addon develop
#updateProject enterprise-skin develop
updateProject openam-addon develop
updateProject remote-edit develop
updateProject saml2-addon develop
updateProject spnego-addon develop
updateProject task develop
updateProject wcm-template-pack develop
updateProject web-conferencing develop
updateProject push-notifications develop
# Not supported starting 5.1.x
# updateProject crash-addon
updateProject exo-es-embedded develop
# Supported since 5.2.0
updateProject lecko develop
# Supported since 5.3.0
updateProject wallet develop
updateProject perk-store develop
updateProject kudos develop
updateProject gamification develop
# Supported since 6.0.x
updateProject news develop
updateProject legacy-intranet develop
updateProject app-center develop
updateProject layout-management develop
updateProject digital-workplace develop
updateProject data-upgrade develop
updateProject onlyoffice develop



## Distrib
updateProject meeds develop
updateProject platform-private-distributions develop
