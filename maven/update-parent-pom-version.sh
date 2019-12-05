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

PREVIOUS_VERSION=19-RC01
NEXT_VERSION=19
ISSUE=SWF-5028
PROJECT=cf-parent

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
updateProject addons-parent-pom stable/11.x
updateProject maven-depmgt-pom stable/16.x
# updateProject juzu master # # stable/1.2.x

updateProject gatein-wci stable/5.3.x
updateProject kernel stable/5.3.x
updateProject core stable/5.3.x
updateProject ws stable/5.3.x
updateProject jcr stable/5.3.x
updateProject gatein-dep stable/1.8.x
updateProject gatein-sso stable/5.3.x
updateProject gatein-pc stable/5.3.x
updateProject gatein-portal stable/5.3.x

## PLF
updateProject docs-style stable/5.3.x
updateProject platform-ui stable/5.3.x
updateProject commons stable/5.3.x
updateProject ecms stable/5.3.x
updateProject social stable/5.3.x
updateProject wiki stable/5.3.x
updateProject forum stable/5.3.x
updateProject calendar stable/5.3.x
updateProject integration stable/5.3.x
updateProject platform stable/5.3.x

## Addons
updateProject addons-manager # stable/1.5.x
# Not supported starting from 5.2.0
# updateProject answers # stable/2.1.x
updateProject cas-addon stable/2.3.x
updateProject chat-application stable/2.3.x
updateProject cmis-addon stable/5.3.x
updateProject enterprise-skin stable/5.3.x
updateProject openam-addon stable/2.3.x
updateProject remote-edit stable/2.3.x
updateProject saml2-addon stable/2.3.x
updateProject spnego-addon stable/2.3.x
updateProject task stable/2.3.x
updateProject wcm-template-pack stable/2.3.x
updateProject web-conferencing stable/1.4.x
updateProject push-notifications stable/1.2.x
# Not supported starting 5.1.x
# updateProject crash-addon
updateProject exo-es-embedded stable/2.3.x
# Supported since 5.2.0
updateProject lecko stable/1.4.x
# Supported since 5.3.0
updateProject wallet stable/1.0.x
updateProject perk-store stable/1.1.x
updateProject kudos stable/1.1.x
updateProject gamification stable/1.2.x


## Distrib
updateProject platform-public-distributions stable/5.3.x
updateProject platform-private-distributions stable/5.3.x
# Not released since 5.3.0
#updateProject platform-private-trial-distributions # stable/5.1.x
