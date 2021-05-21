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

PREVIOUS_VERSION=23-M06
NEXT_VERSION=23-M08
ISSUE=TASK-44549
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

#Meeds Projects
updateProject gatein-dep develop
updateProject gatein-wci develop
updateProject kernel develop
updateProject core develop
updateProject ws develop
updateProject gatein-pc develop
updateProject gatein-sso develop
updateProject gatein-portal develop
updateProject maven-depmgt-pom develop
updateProject platform-ui develop
updateProject commons develop
updateProject social develop
updateProject addons-manager develop
updateProject app-center develop
updateProject gamification develop
updateProject kudos develop
updateProject perk-store develop
updateProject exo-es-embedded develop
updateProject wallet develop
updateProject meeds develop
updateProject push-notifications develop
updateProject notes develop

# Explatform Projects
updateProject ecms develop
updateProject jcr develop
updateProject agenda develop
updateProject analytics develop
updateProject jitsi develop
updateProject jitsi-call develop
updateProject cas-addon develop
updateProject chat-application develop
updateProject cmis-addon develop
updateProject data-upgrade develop
updateProject digital-workplace develop
updateProject layout-management develop
updateProject legacy-intranet develop
updateProject news develop
updateProject onlyoffice develop
updateProject remote-edit develop
updateProject saml2-addon develop
updateProject spnego-addon develop
updateProject task develop
updateProject web-conferencing develop
updateProject data-upgrade develop
updateProject analytics develop
updateProject platform-private-distributions develop
