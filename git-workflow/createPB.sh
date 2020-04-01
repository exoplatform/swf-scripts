#!/bin/bash -eu

# Create a project branch on exodev repositories (and exoplatform for private projects)
# based on a stable branch or a release tag
# target branch name = ${TARGET_BRANCH_PREFIX}/${BRANCH} (the plf version is not kept because can change after the branch creation)
# for example : /project/acc210 
# project version is on the form 5.1.x-acc210-SNAPSHOT on the form 

# Create Git Feature Branches for PLF projects
BRANCH=spaces-groups-binding
ISSUE=ITOP-4787
# Empty if start point is a tag, stable/ for a stable branch
ORIGIN_BRANCH_PREFIX=   # stable/
TARGET_BRANCH_PREFIX=project/

DEFAULT_ORIGIN_BRANCH=5.3.2
DEFAULT_TARGET_BRANCH=${TARGET_BRANCH_PREFIX}5.3.2-${BRANCH}

DEFAULT_ORIGIN_VERSION=5.3.2
DEFAULT_TARGET_VERSION=5.3.2-$BRANCH-SNAPSHOT

# Maven DEPMGT
DEPMGT_ORIGIN_BRANCH=16.2
DEPMGT_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
DEPMGT_ORIGIN_VERSION=${DEPMGT_ORIGIN_BRANCH} #.x-SNAPSHOT
DEPMGT_TARGET_VERSION=16.2-$BRANCH-SNAPSHOT

# GateIn DEPMGT
GATEIN_DEP_ORIGIN_BRANCH=1.8.2
GATEIN_DEP_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
GATEIN_DEP_ORIGIN_VERSION=${GATEIN_DEP_ORIGIN_BRANCH} #.x-SNAPSHOT
GATEIN_DEP_TARGET_VERSION=1.8.2-$BRANCH-SNAPSHOT 

# Add-on manager
ADDONS_MANAGER_ORIGIN_BRANCH=1.5.2
ADDONS_MANAGER_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDONS_MANAGER_ORIGIN_VERSION=${ADDONS_MANAGER_ORIGIN_BRANCH}   #.x-SNAPSHOT
ADDONS_MANAGER_TARGET_VERSION=1.5.2-${BRANCH}-SNAPSHOT

# Add-on Answers
ADDON_ANSWERS_ORIGIN_BRANCH=2.1.3-CP01
ADDON_ANSWERS_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_ANSWERS_ORIGIN_VERSION=${ADDON_ANSWERS_ORIGIN_BRANCH}  #.x-SNAPSHOT
ADDON_ANSWERS_TARGET_VERSION=2.1.3-CP01-$BRANCH-SNAPSHOT

# Add-on CAS
ADDON_CAS_ORIGIN_BRANCH=2.3.2
ADDON_CAS_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_CAS_ORIGIN_VERSION=${ADDON_CAS_ORIGIN_BRANCH}  #.x-SNAPSHOT
ADDON_CAS_TARGET_VERSION=2.3.2-${BRANCH}-SNAPSHOT

# Add-on eXo Chat
ADDON_CHAT_ORIGIN_BRANCH=2.3.2
ADDON_CHAT_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_CHAT_ORIGIN_VERSION=${ADDON_CHAT_ORIGIN_BRANCH} #.x-SNAPSHOT
ADDON_CHAT_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on eXo ElasticSearch Embedded
ADDON_ES_EMBED_ORIGIN_BRANCH=2.3.2
ADDON_ES_EMBED_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_ES_EMBED_ORIGIN_VERSION=${ADDON_ES_EMBED_ORIGIN_BRANCH} #.x-SNAPSHOT
ADDON_ES_EMBED_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on eXo Gamification
ADDON_GAMIFICATION_ORIGIN_BRANCH=1.2.2
ADDON_GAMIFICATION_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_GAMIFICATION_ORIGIN_VERSION=${ADDON_GAMIFICATION_ORIGIN_BRANCH} #.x-SNAPSHOT
ADDON_GAMIFICATION_TARGET_VERSION=1.2.2-$BRANCH-SNAPSHOT

# Add-on eXo Kudos
ADDON_KUDOS_ORIGIN_BRANCH=1.1.2
ADDON_KUDOS_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_KUDOS_ORIGIN_VERSION=${ADDON_KUDOS_ORIGIN_BRANCH} #.x-SNAPSHOT
ADDON_KUDOS_TARGET_VERSION=1.1.2-$BRANCH-SNAPSHOT

# Add-on eXo Lecko !!not available before 5.2.x!!
ADDON_LECKO_ORIGIN_BRANCH=1.4.2
ADDON_LECKO_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_LECKO_ORIGIN_VERSION=${ADDON_LECKO_ORIGIN_BRANCH}  #.x-SNAPSHOT 
ADDON_LECKO_TARGET_VERSION=1.4.2-$BRANCH-SNAPSHOT

# Add-on OpenAM
ADDON_OPENAM_ORIGIN_BRANCH=2.3.2
ADDON_OPENAM_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_OPENAM_CURRENT_VERSION=${ADDON_OPENAM_ORIGIN_BRANCH}   #.x-SNAPSHOT
ADDON_OPENAM_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on eXo OnlyOffice
ADDON_ONLYOFFICE_ORIGIN_BRANCH=1.5.2
ADDON_ONLYOFFICE_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_ONLYOFFICE_CURRENT_VERSION=${ADDON_ONLYOFFICE_ORIGIN_BRANCH}
ADDON_ONLYOFFICE_TARGET_VERSION=1.5.2-$BRANCH-SNAPSHOT

# Add-on eXo Perk Store
ADDON_PERK_STORE_ORIGIN_BRANCH=1.1.2
ADDON_PERK_STORE_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_PERK_STORE_ORIGIN_VERSION=${ADDON_PERK_STORE_ORIGIN_BRANCH}  #.x-SNAPSHOT
ADDON_PERK_STORE_TARGET_VERSION=1.1.2-$BRANCH-SNAPSHOT

# Add-on eXo Push notifications
ADDON_PUSH_NOTIFICATIONS_ORIGIN_BRANCH=1.2.2
ADDON_PUSH_NOTIFICATIONS_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION=${ADDON_PUSH_NOTIFICATIONS_ORIGIN_BRANCH}  #.x-SNAPSHOT
ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION=1.2.2-$BRANCH-SNAPSHOT

# Add-on eXo Remote Edit
ADDON_REMOTE_EDIT_ORIGIN_BRANCH=2.3.2
ADDON_REMOTE_EDIT_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_REMOTE_EDIT_ORIGIN_VERSION=${ADDON_REMOTE_EDIT_ORIGIN_BRANCH}  #.x-SNAPSHOT
ADDON_REMOTE_EDIT_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on Saml
ADDON_SAML2_ORIGIN_BRANCH=2.3.2
ADDON_SAML2_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_SAML2_ORIGIN_VERSION=${ADDON_SAML2_ORIGIN_BRANCH}  #  #.x-SNAPSHOT
ADDON_SAML2_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on SPNEGO
ADDON_SPNEGO_ORIGIN_BRANCH=2.3.2
ADDON_SPNEGO_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_SPNEGO_ORIGIN_VERSION=${ADDON_SPNEGO_ORIGIN_BRANCH}   #.x-SNAPSHOT
ADDON_SPNEGO_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on eXo Task
ADDON_TASK_ORIGIN_BRANCH=2.3.2
ADDON_TASK_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_TASK_ORIGIN_VERSION=${ADDON_TASK_ORIGIN_BRANCH} #.x-SNAPSHOT
ADDON_TASK_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

# Add-on eXo Web Conferencing
ADDON_WEB_CONFERENCING_ORIGIN_BRANCH=1.4.2
ADDON_WEB_CONFERENCING_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH}
ADDON_WEB_CONFERENCING_ORIGIN_VERSION=${ADDON_WEB_CONFERENCING_ORIGIN_BRANCH}  #.x-SNAPSHOT 
ADDON_WEB_CONFERENCING_TARGET_VERSION=1.4.2-$BRANCH-SNAPSHOT

# Add-on eXo Web Pack
ADDON_WEB_PACK_ORIGIN_BRANCH=2.3.2
ADDON_WEB_PACK_TARGET_BRANCH=${DEFAULT_TARGET_BRANCH} 
ADDON_WEB_PACK_ORIGIN_VERSION=${ADDON_WEB_PACK_ORIGIN_BRANCH}  #.x-SNAPSHOT
ADDON_WEB_PACK_TARGET_VERSION=2.3.2-$BRANCH-SNAPSHOT

SCRIPTDIR=$(
	cd $(dirname "$0")
	pwd
)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}

GIT_PUSH_PARAMS=""
PUSH=false

while getopts "p" opt; do
	case $opt in
	p)
		PUSH=true
		;;
	esac
done

function repoInit() {
	local devOrga=$1
	local repository=$2
	local startBranch=$3

	# Add the dev orga remote if not already present
	if [ "$devOrga" != "exoplatform" -a "$devOrga" != "juzu" ]; then
		devRepoUrl="git@github.com:${devOrga}/${repository}"
		echo "Testing dev repository declaration (${devRepoUrl})..."
		if [ $(git remote -vv | grep -c ${devRepoUrl}) -eq 0 ]; then
			echo "Installing dev repository..."
			git remote add ${devOrga} ${devRepoUrl}
			git fetch ${devOrga}
		fi
		# Reset to develop branch to ensure everything is clean
		git reset --hard ${devOrga}/develop
	fi

	# git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
	printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
	git remote update --prune
	git reset --hard HEAD
	git checkout develop
	git pull --tags
	git checkout ${startBranch}
	# if start point is a branch, resetting on it
	if [ $(git ls-remote --heads origin ${startBranch} | wc -l) -gt 0 ]; then 
		git reset --hard origin/${startBranch}
	fi

}

function createBranch() {
	repoName=$1
	originBranch=$2
	projectBranch=$3

	printf "\e[1;33m# %s\e[m\n" "Testing if ${projectBranch} branch doesn't already exists and reuse it (${repoName}) ..."
	set +e
	GIT_PUSH_PARAMS=""
	git checkout ${projectBranch}
	if [ "$?" -ne "0" ]; then
		git checkout -b ${projectBranch}
	else
		printf "\e[1;35m# %s\e[m\n" "WARNING : the ${projectBranch} branch already exists so we will delete it (you have 5 seconds to cancel with CTRL+C) (${repoName}) ..."
		# sleep 5
		git checkout ${originBranch}
		git branch -D ${projectBranch}
		git checkout -b ${projectBranch}
		GIT_PUSH_PARAMS="--force"
	fi
}

function replaceProjectVersion() {
	local repoName=$1
	local originVersion=$2
	local targetVersion=$3 

	printf "\e[1;33m# %s\e[m\n" "Modifying versions in the project POMs ($repo_name) from ${originVersion} to ${targetVersion}..."
	set +e
	$SCRIPTDIR/../replaceInPom.sh "<version>${originVersion}</version>" "<version>${targetVersion}</version>"
	set -e

	local changes=$(git status -s | grep "^ M" -c)
	if [ ${changes} -lt 1 ]; then
		printf "\e[1;35m# %s\e[m\n" "No changes detected on ${repository} after pom version update"
		exit 1
	else
		printf "\e[1;33m# %s\e[m\n" "OK ${changes} files updated detected"
	fi

}

function replaceProjectDeps() {
	local repoName=$1

	printf "\e[1;33m# %s\e[m\n" "Modifying dependencies versions in the project POMs ($repoName) ..."

	## GateIn Dep
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.dep.version>$GATEIN_DEP_ORIGIN_VERSION</org.exoplatform.gatein.dep.version>" "<org.exoplatform.gatein.dep.version>$GATEIN_DEP_TARGET_VERSION</org.exoplatform.gatein.dep.version>"

	## GateIn WCI
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.wci.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.gatein.wci.version>" "<org.exoplatform.gatein.wci.version>$DEFAULT_TARGET_VERSION</org.exoplatform.gatein.wci.version>"

	## CF
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.kernel.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>$DEFAULT_TARGET_VERSION</org.exoplatform.kernel.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.core.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.core.version>" "<org.exoplatform.core.version>$DEFAULT_TARGET_VERSION</org.exoplatform.core.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ws.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>$DEFAULT_TARGET_VERSION</org.exoplatform.ws.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.jcr.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>$DEFAULT_TARGET_VERSION</org.exoplatform.jcr.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.jcr-services.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.jcr-services.version>" "<org.exoplatform.jcr-services.version>$DEFAULT_TARGET_VERSION</org.exoplatform.jcr-services.version>"

	## GateIn
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.sso.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.gatein.sso.version>" "<org.exoplatform.gatein.sso.version>$DEFAULT_TARGET_VERSION</org.exoplatform.gatein.sso.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.pc.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.gatein.pc.version>" "<org.exoplatform.gatein.pc.version>$DEFAULT_TARGET_VERSION</org.exoplatform.gatein.pc.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.gatein.portal.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.gatein.portal.version>" "<org.exoplatform.gatein.portal.version>$DEFAULT_TARGET_VERSION</org.exoplatform.gatein.portal.version>"

	## PLF
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.depmgt.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>$DEFAULT_TARGET_VERSION</org.exoplatform.depmgt.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.doc.doc-style.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>$DEFAULT_TARGET_VERSION</org.exoplatform.doc.doc-style.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform-ui.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$DEFAULT_TARGET_VERSION</org.exoplatform.platform-ui.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.commons.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$DEFAULT_TARGET_VERSION</org.exoplatform.commons.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.ecms.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$DEFAULT_TARGET_VERSION</org.exoplatform.ecms.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.social.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$DEFAULT_TARGET_VERSION</org.exoplatform.social.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.wiki.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$DEFAULT_TARGET_VERSION</org.exoplatform.wiki.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.forum.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$DEFAULT_TARGET_VERSION</org.exoplatform.forum.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.calendar.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$DEFAULT_TARGET_VERSION</org.exoplatform.calendar.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.integ.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$DEFAULT_TARGET_VERSION</org.exoplatform.integ.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$DEFAULT_TARGET_VERSION</org.exoplatform.platform.version>"
	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.distributions.version>$DEFAULT_ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$DEFAULT_TARGET_VERSION</org.exoplatform.platform.distributions.version>"
}

function replaceProjectAddons() {
	local repoName=$1
	printf "\e[1;33m# %s\e[m\n" "Modifying add-ons versions in the packaging project POMs ($repoName) ..."

	$SCRIPTDIR/../replaceInPom.sh "<org.exoplatform.platform.addons-manager.version>$ADDONS_MANAGER_ORIGIN_VERSION</org.exoplatform.platform.addons-manager.version>" "<org.exoplatform.platform.addons-manager.version>$ADDONS_MANAGER_TARGET_VERSION</org.exoplatform.platform.addons-manager.version>"

	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.answers.version>$ADDON_ANSWERS_ORIGIN_VERSION</addon.exo.answers.version>" "<addon.exo.answers.version>$ADDON_ANSWERS_TARGET_VERSION</addon.exo.answers.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.chat.version>$ADDON_CHAT_ORIGIN_VERSION</addon.exo.chat.version>" "<addon.exo.chat.version>$ADDON_CHAT_TARGET_VERSION</addon.exo.chat.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.enterprise-skin.version>$DEFAULT_ORIGIN_VERSION</addon.exo.enterprise-skin.version>" "<addon.exo.enterprise-skin.version>$DEFAULT_TARGET_VERSION</addon.exo.enterprise-skin.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.es.embedded.version>$ADDON_ES_EMBED_ORIGIN_VERSION</addon.exo.es.embedded.version>" "<addon.exo.es.embedded.version>$ADDON_ES_EMBED_TARGET_VERSION</addon.exo.es.embedded.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.push-notifications.version>$ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION</addon.exo.push-notifications.version>" "<addon.exo.push-notifications.version>$ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION</addon.exo.push-notifications.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.remote-edit.version>$ADDON_REMOTE_EDIT_ORIGIN_VERSION</addon.exo.remote-edit.version>" "<addon.exo.remote-edit.version>$ADDON_REMOTE_EDIT_TARGET_VERSION</addon.exo.remote-edit.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.tasks.version>$ADDON_TASK_ORIGIN_VERSION</addon.exo.tasks.version>" "<addon.exo.tasks.version>$ADDON_TASK_TARGET_VERSION</addon.exo.tasks.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.web-conferencing.version>$ADDON_WEB_CONFERENCING_ORIGIN_VERSION</addon.exo.web-conferencing.version>" "<addon.exo.web-conferencing.version>$ADDON_WEB_CONFERENCING_TARGET_VERSION</addon.exo.web-conferencing.version>"
	$SCRIPTDIR/../replaceInPom.sh "<addon.exo.web-pack.version>$ADDON_WEB_PACK_ORIGIN_VERSION</addon.exo.web-pack.version>" "<addon.exo.web-pack.version>$ADDON_WEB_PACK_TARGET_VERSION</addon.exo.web-pack.version>"
}

function commitAndPushChanges() {
	local devOrga=$1
	local branch=$2
	local remoteName=""

	if [ "$devOrga" == "exoplatform" ] || [ "$devOrga" == "juzu" ]; then
		remoteName=origin
	else
		remoteName=${devOrga}
	fi

	printf "\e[1;33m# %s\e[m\n" "Commiting changes ..."
	git commit -m "$ISSUE: Create PB $branch and update projects versions/dependencies" -a

	if $PUSH; then
		printf "\e[1;33m# %s\e[m\n" "Pushing commit to ${branch} ..."
		git push $GIT_PUSH_PARAMS ${remoteName} ${branch} --set-upstream
	else
		printf "\e[1;35m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;33m# %s\e[m\n" "Following command would have been executed : |git push $GIT_PUSH_PARAMS ${remoteName} ${branch} --set-upstream|"
	fi 
	git checkout develop
}

function createPB() {
	local repository=$1
	local devOrga=$2

	#update project versions for project not following PLF versionning  branch
	local startBranch=""
	local projectBranch=""
	local startVersion=""
	local projectBranchVersion=""

	case $repository in
	gatein-dep)
		startBranch=${ORIGIN_BRANCH_PREFIX}${GATEIN_DEP_ORIGIN_BRANCH}
		startVersion=${GATEIN_DEP_ORIGIN_VERSION}
		projectBranch=${GATEIN_DEP_TARGET_BRANCH}
		projectBranchVersion=${GATEIN_DEP_TARGET_VERSION}
		;;
	maven-depmgt-pom)
		startBranch=${ORIGIN_BRANCH_PREFIX}${DEPMGT_ORIGIN_BRANCH}
		startVersion=${DEPMGT_ORIGIN_VERSION}
		projectBranch=${DEPMGT_TARGET_BRANCH}
		projectBranchVersion=${DEPMGT_TARGET_VERSION}
		;;
	addons-manager)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDONS_MANAGER_ORIGIN_BRANCH}
		startVersion=${ADDONS_MANAGER_ORIGIN_VERSION}
		projectBranch=${ADDONS_MANAGER_TARGET_BRANCH}
		projectBranchVersion=${ADDONS_MANAGER_TARGET_VERSION}
		;;
	answers)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_ANSWERS_ORIGIN_BRANCH}
		startVersion=${ADDON_ANSWERS_ORIGIN_VERSION}
		projectBranch=${ADDON_ANSWERS_TARGET_BRANCH}
		projectBranchVersion=${ADDON_ANSWERS_TARGET_VERSION}
		;;
    cas-addon)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_CAS_ORIGIN_BRANCH}
		startVersion=${ADDON_CAS_ORIGIN_VERSION}
		projectBranch=${ADDON_CAS_TARGET_BRANCH}
		projectBranchVersion=${ADDON_CAS_TARGET_VERSION}
		;;
	chat-application)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_CHAT_ORIGIN_BRANCH}
		startVersion=${ADDON_CHAT_ORIGIN_VERSION}
		projectBranch=${ADDON_CHAT_TARGET_BRANCH}
		projectBranchVersion=${ADDON_CHAT_TARGET_VERSION}
		;;
	exo-es-embedded)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_ES_EMBED_ORIGIN_BRANCH}
		startVersion=${ADDON_ES_EMBED_ORIGIN_VERSION}
		projectBranch=${ADDON_ES_EMBED_TARGET_BRANCH}
		projectBranchVersion=${ADDON_ES_EMBED_TARGET_VERSION}
		;;
	gamification)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_GAMIFICATION_ORIGIN_BRANCH}
		startVersion=${ADDON_GAMIFICATION_ORIGIN_VERSION}
		projectBranch=${ADDON_GAMIFICATION_TARGET_BRANCH}
		projectBranchVersion=${ADDON_GAMIFICATION_TARGET_VERSION}
		;;
	kudos)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_KUDOS_ORIGIN_BRANCH}
		startVersion=${ADDON_KUDOS_ORIGIN_VERSION}
		projectBranch=${ADDON_KUDOS_TARGET_BRANCH}
		projectBranchVersion=${ADDON_KUDOS_TARGET_VERSION}
		;;	
	lecko)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_LECKO_ORIGIN_BRANCH}
		startVersion=${ADDON_LECKO_ORIGIN_VERSION}
		projectBranch=${ADDON_LECKO_TARGET_BRANCH}
		projectBranchVersion=${ADDON_LECKO_TARGET_VERSION}
		;;
	onlyoffice)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_ONLYOFFICE_ORIGIN_BRANCH}
		startVersion=${ADDON_ONLYOFFICE_CURRENT_VERSION}
		projectBranch=${ADDON_ONLYOFFICE_TARGET_BRANCH}
		projectBranchVersion=${ADDON_ONLYOFFICE_TARGET_VERSION}
		;;
	openam-addon)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_OPENAM_ORIGIN_BRANCH}
		startVersion=${ADDON_OPENAM_CURRENT_VERSION}
		projectBranch=${ADDON_OPENAM_TARGET_BRANCH}
		projectBranchVersion=${ADDON_OPENAM_TARGET_VERSION}
		;;
	perk-store)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_PERK_STORE_ORIGIN_BRANCH}
		startVersion=${ADDON_PERK_STORE_CURRENT_VERSION}
		projectBranch=${ADDON_PERK_STORE_TARGET_BRANCH}
		projectBranchVersion=${ADDON_PERK_STORE_TARGET_VERSION}
		;;	
	remote-edit)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_REMOTE_EDIT_ORIGIN_BRANCH}
		startVersion=${ADDON_REMOTE_EDIT_ORIGIN_VERSION}
		projectBranch=${ADDON_REMOTE_EDIT_TARGET_BRANCH}
		projectBranchVersion=${ADDON_REMOTE_EDIT_TARGET_VERSION}
		;;
	saml2-addon)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_SAML2_ORIGIN_BRANCH}
		startVersion=${ADDON_SAML2_ORIGIN_VERSION}
		projectBranch=${ADDON_SAML2_TARGET_BRANCH}
		projectBranchVersion=${ADDON_SAML2_TARGET_VERSION}
		;;
	spnego-addon)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_SPNEGO_ORIGIN_BRANCH}
		startVersion=${ADDON_SPNEGO_ORIGIN_VERSION}
		projectBranch=${ADDON_SPNEGO_TARGET_BRANCH}
		projectBranchVersion=${ADDON_SPNEGO_TARGET_VERSION}
		;;
	task)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_TASK_ORIGIN_BRANCH}
		startVersion=${ADDON_TASK_ORIGIN_VERSION}
		projectBranch=${ADDON_TASK_TARGET_BRANCH}
		projectBranchVersion=${ADDON_TASK_TARGET_VERSION}
		;;
	wcm-template-pack)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_WEB_PACK_ORIGIN_BRANCH}
		startVersion=${ADDON_WEB_PACK_ORIGIN_VERSION}
		projectBranch=${ADDON_WEB_PACK_TARGET_BRANCH}
		projectBranchVersion=${ADDON_WEB_PACK_TARGET_VERSION}
		;;
	web-conferencing)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_WEB_CONFERENCING_ORIGIN_BRANCH}
		startVersion=${ADDON_WEB_CONFERENCING_ORIGIN_VERSION}
		projectBranch=${ADDON_WEB_CONFERENCING_TARGET_BRANCH}
		projectBranchVersion=${ADDON_WEB_CONFERENCING_TARGET_VERSION}
		;;

	push-notifications)
		startBranch=${ORIGIN_BRANCH_PREFIX}${ADDON_PUSH_NOTIFICATIONS_ORIGIN_BRANCH}
		startVersion=${ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION}
		projectBranch=${ADDON_PUSH_NOTIFICATIONS_TARGET_BRANCH}
		projectBranchVersion=${ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION}
		;;
	*)
		startBranch=${ORIGIN_BRANCH_PREFIX}${DEFAULT_ORIGIN_BRANCH}
		startVersion=${DEFAULT_ORIGIN_VERSION}
		projectBranch=${DEFAULT_TARGET_BRANCH}
		projectBranchVersion=${DEFAULT_TARGET_VERSION}
		;;
	esac


	local repo_name=$1
	printf "\e[1;33m########################################\e[m\n"
	printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
	printf "\e[1;33m########################################\e[m\n"

	if [ ! -d $repo_name ]; then
	  # Control will enter here if $DIRECTORY doesn't exist.
	  git clone git@github.com:$devOrga/$repo_name.git
	fi

	pushd ${repo_name}

	repoInit ${devOrga} ${repository} ${startBranch}

	createBranch ${repository} ${startBranch} ${projectBranch}

	replaceProjectVersion ${repository} ${startVersion} ${projectBranchVersion}
 	replaceProjectDeps ${repository}

	# Replace add-on versions in distributions project
	case $repo_name in
		*-distributions) replaceProjectAddons ${repo_name} ;;
	esac

	commitAndPushChanges ${devOrga} ${projectBranch}

	popd
}

pushd ${SWF_FB_REPOS}

createPB gatein-wci exoplatform
createPB kernel exoplatform
createPB core exoplatform
createPB ws exoplatform
createPB jcr exoplatform
createPB gatein-dep exoplatform
createPB gatein-sso exoplatform
createPB gatein-pc exoplatform
createPB gatein-portal exoplatform

createPB maven-depmgt-pom exoplatform

## PLF
createPB docs-style exoplatform
createPB platform-ui exoplatform
createPB commons exoplatform
createPB ecms exoplatform
createPB social exoplatform
createPB wiki exoplatform
createPB forum exoplatform
createPB calendar exoplatform
createPB integration exoplatform
createPB platform exoplatform

## Addons
createPB addons-manager exoplatform
# Only for version <= 5.1.x
#createPB answers exoplatform
createPB cas-addon exoplatform
createPB chat-application exoplatform
createPB cmis-addon exoplatform
createPB exo-es-embedded exoplatform
createPB enterprise-skin exoplatform
createPB gamification exoplatform
createPB kudos exoplatform
createPB lecko exoplatform
createPB onlyoffice explatform
createPB openam-addon exoplatform
createPB perk-store exoplatform
createPB push-notifications exoplatform
createPB remote-edit exoplatform
createPB saml2-addon exoplatform
createPB spnego-addon exoplatform
createPB task exoplatform
createPB wcm-template-pack exoplatform
createPB web-conferencing exoplatform

## Distrib
createPB platform-public-distributions exoplatform
createPB platform-private-distributions exoplatform
## Not present in 5.3.2
#createPB platform-private-trial-distributions exoplatform

printf "\e[1;33m########################################\e[m\n"
printf "\e[1;33m# Project branch ${DEFAULT_TARGET_BRANCH} created\e[m\n"
printf "\e[1;33m########################################\e[m\n"

popd
