#!/bin/bash

BRANCH_TO_DELETE=feature/kill-shindig
DEFAULT_BRANCH=develop
PUSH=false


function help() {
	cat <<EOF
Usage: $0 [OPTIONS]

Delete a branch from all configured repositories.

Options:
  -b <branch>  Branch to delete.
               Default: ${BRANCH_TO_DELETE}

  -p           Enable push.
               Delete the branch from the remote repository.

  -h           Display this help message.

Examples:
  $0
      Delete '${BRANCH_TO_DELETE}' locally only.

  $0 -b feature/test
      Delete 'feature/test' locally only.

  $0 -b feature/test -p
      Delete 'feature/test' locally and remotely.

  $0 -p
      Delete '${BRANCH_TO_DELETE}' locally and remotely.

  $0 -h
      Display this help message.

Configuration:
  Branch to delete : ${BRANCH_TO_DELETE}
  Default branch   : ${DEFAULT_BRANCH}
  Push enabled     : ${PUSH}
EOF
}

while getopts ":b:ph" opt; do
	case ${opt} in
		b)
			BRANCH_TO_DELETE="${OPTARG}"
			;;
		p)
			PUSH=true
			;;
		h)
			help
			exit 0
			;;
		\?)
			printf "\e[1;31m# %s\e[m\n" \
				"Invalid option: -${OPTARG}"
			help
			exit 1
			;;
		:)
			printf "\e[1;31m# %s\e[m\n" \
				"Option -${OPTARG} requires an argument"
			help
			exit 1
			;;
	esac
done

if [ "${BRANCH_TO_DELETE}" = "${DEFAULT_BRANCH}" ]; then
	printf "\e[1;31m# %s\e[m\n" \
		"ERROR: refusing to delete ${DEFAULT_BRANCH}"
	exit 1
fi

function deleteGitBranch() {
	local repo_name=$1
	local organization=$2
  
  if [ "${BRANCH_TO_DELETE}" = "${DEFAULT_BRANCH}" ]; then
		printf "\e[1;31m# %s\e[m\n" \
			"ERROR: refusing to delete ${DEFAULT_BRANCH}"
		return 1
	fi

	if [ ! -d "${repo_name}" ]; then
		printf "\e[1;33m# %s\e[m\n" \
			"Repo ${repo_name} does not exist, cloning it ..."

		git clone "git@github.com:${organization}/${repo_name}.git" "${repo_name}"
	else
		printf "\e[1;33m# %s\e[m\n" \
			"Repo ${repo_name} already exists, skipping clone"
	fi

	printf "\e[1;33m# %s\e[m\n" \
		"Cleaning of ${repo_name} repository ..."

	pushd "${repo_name}" >/dev/null || return 1

	git remote update --prune
	git reset --hard HEAD
	git clean -df

	if ! git checkout "${DEFAULT_BRANCH}"; then
		printf "\e[1;31m# %s\e[m\n" \
			"Failed to checkout ${DEFAULT_BRANCH} in ${repo_name}"
		popd >/dev/null
		return 1
	fi

	git reset --hard "origin/${DEFAULT_BRANCH}"

	printf "\e[1;33m# %s\e[m\n" \
		"Deleting ${BRANCH_TO_DELETE} branch locally (${repo_name}) ..."

	if git rev-parse --verify --quiet "${BRANCH_TO_DELETE}" >/dev/null; then
		git branch -D "${BRANCH_TO_DELETE}"
	else
		printf "\e[1;35m# %s\e[m\n" \
			"Local branch ${BRANCH_TO_DELETE} does not exist, skipping ..."
	fi

	if [ "${PUSH}" = true ]; then
		printf "\e[1;33m# %s\e[m\n" \
			"Deleting ${BRANCH_TO_DELETE} branch remotely (${repo_name}) ..."

		if git ls-remote --exit-code --heads origin "${BRANCH_TO_DELETE}" >/dev/null 2>&1; then
			git push origin --delete "${BRANCH_TO_DELETE}"
		else
			printf "\e[1;35m# %s\e[m\n" \
				"Remote branch ${BRANCH_TO_DELETE} does not exist, skipping ..."
		fi
	else
		printf "\e[1;35m# %s\e[m\n" \
			"Push disabled: remote branch ${BRANCH_TO_DELETE} will not be deleted"
	fi

	popd >/dev/null
}

#Meeds Projects
deleteGitBranch maven-depmgt-pom Meeds-io
deleteGitBranch gatein-wci Meeds-io
deleteGitBranch kernel Meeds-io
deleteGitBranch core Meeds-io
deleteGitBranch ws Meeds-io
deleteGitBranch portlet-container Meeds-io
deleteGitBranch gatein-sso Meeds-io
deleteGitBranch portal Meeds-io
deleteGitBranch platform-ui Meeds-io
deleteGitBranch commons Meeds-io
deleteGitBranch social Meeds-io
deleteGitBranch layout Meeds-io
deleteGitBranch auth-server Meeds-io
deleteGitBranch gamification Meeds-io
deleteGitBranch kudos Meeds-io
deleteGitBranch perk-store Meeds-io
deleteGitBranch wallet Meeds-io
deleteGitBranch push-notifications Meeds-io
deleteGitBranch app-center Meeds-io
deleteGitBranch mcp-server Meeds-io
deleteGitBranch analytics Meeds-io
deleteGitBranch notes Meeds-io
deleteGitBranch content Meeds-io
deleteGitBranch poll Meeds-io
deleteGitBranch task Meeds-io
deleteGitBranch gamification-github Meeds-io
deleteGitBranch gamification-twitter Meeds-io
deleteGitBranch gamification-evm Meeds-io
deleteGitBranch gamification-crowdin Meeds-io
deleteGitBranch pwa Meeds-io
deleteGitBranch ide Meeds-io
deleteGitBranch matrix Meeds-io
deleteGitBranch ai Meeds-io
deleteGitBranch addons-manager Meeds-io
deleteGitBranch deeds-tenant Meeds-io
deleteGitBranch meeds Meeds-io
deleteGitBranch billing Meeds-io

#  # # Explatform projects
deleteGitBranch maven-exo-depmgt-pom exoplatform
deleteGitBranch commons-exo exoplatform
deleteGitBranch jcr exoplatform
deleteGitBranch ecms exoplatform
deleteGitBranch email-connector exoplatform
deleteGitBranch dlp exoplatform
deleteGitBranch agenda exoplatform
deleteGitBranch agenda-connectors exoplatform
deleteGitBranch digital-workplace exoplatform
deleteGitBranch onlyoffice exoplatform
deleteGitBranch saml2-addon exoplatform
deleteGitBranch web-conferencing exoplatform
deleteGitBranch jitsi-call exoplatform
deleteGitBranch jitsi exoplatform
deleteGitBranch multifactor-authentication exoplatform
deleteGitBranch automatic-translation exoplatform
deleteGitBranch documents exoplatform
deleteGitBranch processes exoplatform
deleteGitBranch data-upgrade exoplatform
deleteGitBranch anti-bruteforce exoplatform
deleteGitBranch anti-malware exoplatform
deleteGitBranch external-visio-connector exoplatform
deleteGitBranch caldav-integration exoplatform
deleteGitBranch platform-private-distributions exoplatform
deleteGitBranch platform-public-distributions exoplatform

#popd
exit
