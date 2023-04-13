#!/bin/bash -eu

# Create Git Feature Branches for PLF projects
BRANCH=$1
ISSUE=$3
ORIGIN_BRANCH=$2 # develop-meed or develop 
PUSH=$4
DEFAULT_BRANCH=develop
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=6.5.x-SNAPSHOT
TARGET_VERSION=6.5.x-$BRANCH-SNAPSHOT
MEEDS_DISTRIB="-exo" # '-meed' or ''

# Maven DEPMGT
DEPMGT_ORIGIN_VERSION=22.x${MEEDS_DISTRIB}-SNAPSHOT
DEPMGT_TARGET_VERSION=22.x-$BRANCH-SNAPSHOT
# Add-on Meeds Gamification
ADDON_GAMIFICATION_ORIGIN_VERSION=2.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDON_GAMIFICATION_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on Meeds Perk Store
ADDON_PERK_STORE_ORIGIN_VERSION=2.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDON_PERK_STORE_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on Meeds Push notifications
ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION=2.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on Meeds Task
ADDON_TASK_ORIGIN_VERSION=3.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDON_TASK_TARGET_VERSION=3.5.x-$BRANCH-SNAPSHOT
# Add-on Meeds Wallet
ADDON_WALLET_ORIGIN_VERSION=2.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDON_WALLET_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on Meeds App Center
ADDON_APP_CENTER_ORIGIN_VERSION=2.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDON_APP_CENTER_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on manager
ADDONS_MANAGER_ORIGIN_VERSION=2.5.x${MEEDS_DISTRIB}-SNAPSHOT
ADDONS_MANAGER_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on Meeds Notes
ADDONS_NOTES_ORIGIN_VERSION=1.3.x${MEEDS_DISTRIB}-SNAPSHOT
ADDONS_NOTES_TARGET_VERSION=1.3.x-$BRANCH-SNAPSHOT
# Add-on Meeds Analytics
ADDONS_ANALYTICS_ORIGIN_VERSION=1.4.x${MEEDS_DISTRIB}-SNAPSHOT
ADDONS_ANALYTICS_TARGET_VERSION=1.4.x-$BRANCH-SNAPSHOT
# Add-on Meeds poll
ADDONS_POLL_ORIGIN_VERSION=1.2.x${MEEDS_DISTRIB}-SNAPSHOT
ADDONS_POLL_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT
# Add-on Meeds Gamification-github
ADDONS_GAMIFICATION_GITHUB_ORIGIN_VERSION=1.2.x${MEEDS_DISTRIB}-SNAPSHOT
ADDONS_GAMIFICATION_GITHUB_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT
# Meeds Distribution
MEEDS_ORIGIN_VERSION=1.5.x-SNAPSHOT
MEEDS_TARGET_VERSION=1.5.x-$BRANCH-SNAPSHOT

# Add-on eXo Chat
ADDON_CHAT_ORIGIN_VERSION=3.5.x-SNAPSHOT
ADDON_CHAT_TARGET_VERSION=3.5.x-$BRANCH-SNAPSHOT
# Add-on DW Homepage
ADDON_DIGITAL_WORKPLACE_ORIGIN_VERSION=1.5.x-SNAPSHOT
ADDON_DIGITAL_WORKPLACE_TARGET_VERSION=1.5.x-$BRANCH-SNAPSHOT
# Add-on eXo Kudos
ADDON_KUDOS_ORIGIN_VERSION=2.5.x-SNAPSHOT
ADDON_KUDOS_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on eXo Layout Management
ADDON_LAYOUT_MANAGEMENT_ORIGIN_VERSION=1.5.x-SNAPSHOT
ADDON_LAYOUT_MANAGEMENT_TARGET_VERSION=1.5.x-$BRANCH-SNAPSHOT
# Add-on eXo news
ADDON_NEWS_ORIGIN_VERSION=2.5.x-SNAPSHOT
ADDON_NEWS_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on eXo OnlyOffice
ADDON_ONLYOFFICE_ORIGIN_VERSION=2.5.x-SNAPSHOT
ADDON_ONLYOFFICE_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on eXo saml2	
ADDON_SAML2_ORIGIN_VERSION=3.5.x-SNAPSHOT
ADDON_SAML2_TARGET_VERSION=3.5.x-$BRANCH-SNAPSHOT
# Add-on eXo Web Conferencing
ADDON_WEB_CONFERENCING_ORIGIN_VERSION=2.5.x-SNAPSHOT
ADDON_WEB_CONFERENCING_TARGET_VERSION=2.5.x-$BRANCH-SNAPSHOT
# Add-on eXo agenda
ADDONS_AGENDA_ORIGIN_VERSION=1.4.x-SNAPSHOT
ADDONS_AGENDA_TARGET_VERSION=1.4.x-$BRANCH-SNAPSHOT
# Add-on eXo Data upgrade
ADDONS_DATA_UPGRADE_ORIGIN_VERSION=6.5.x-SNAPSHOT
ADDONS_DATA_UPGRADE_TARGET_VERSION=6.5.x-$BRANCH-SNAPSHOT
# Add-on eXo jitsi
ADDONS_JITSI_ORIGIN_VERSION=1.4.x-SNAPSHOT
ADDONS_JITSI_TARGET_VERSION=1.4.x-$BRANCH-SNAPSHOT
# Add-on eXo Multifactor Authentication
ADDONS_MULTIFACTOR_AUTHENTICATION_ORIGIN_VERSION=1.3.x-SNAPSHOT
ADDONS_MULTIFACTOR_AUTHENTICATION_TARGET_VERSION=1.3.x-$BRANCH-SNAPSHOT
# Add-on eXo processes
ADDONS_PROCESSES_ORIGIN_VERSION=1.2.x-SNAPSHOT
ADDONS_PROCESSES_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT
# Automatic Translation
ADDONS_AUTOMATIC_TRANSLATION_ORIGIN_VERSION=1.2.x-SNAPSHOT
ADDONS_AUTOMATIC_TRANSLATION_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT
# Add-on eXo Documents
ADDONS_DOCUMENTS_ORIGIN_VERSION=1.2.x-SNAPSHOT
ADDONS_DOCUMENTS_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT
# Add-on mail-integration
ADDONS_MAIL_INTEGRATION_ORIGIN_VERSION=1.2.x-SNAPSHOT
ADDONS_MAIL_INTEGRATION_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT
# Add-on Anti-bruteforce
ADDONS_ANTI_BRUTEFORCE_ORIGIN_VERSION=1.1.x-SNAPSHOT
ADDONS_ANTI_BRUTEFORCE_TARGET_VERSION=1.1.x-$BRANCH-SNAPSHOT
# Add-on Anti-malware
ADDONS_ANTI_MALWARE_ORIGIN_VERSION=1.1.x-SNAPSHOT
ADDONS_ANTI_MALWARE_TARGET_VERSION=1.1.x-$BRANCH-SNAPSHOT
# Add-on dlp
ADDONS_DLP_ORIGIN_VERSION=1.1.x-SNAPSHOT
ADDONS_DLP_TARGET_VERSION=1.1.x-$BRANCH-SNAPSHOT
# Add-on agenda connectors
ADDONS_AGENDA_CONNECTORS_ORIGIN_VERSION=1.2.x-SNAPSHOT
ADDONS_AGENDA_CONNECTORS_TARGET_VERSION=1.2.x-$BRANCH-SNAPSHOT

SCRIPTDIR=$(
	cd $(dirname "$0")
	pwd
)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}
echo "==================================="
echo "SWF_FB_REPOS : ${SWF_FB_REPOS}"
echo "==================================="

# function repoInit() {
# 	local repo_name=$1
# 	printf "\e[1;33m########################################\e[m\n"
# 	printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
# 	printf "\e[1;33m########################################\e[m\n"
# 	#pushd repo-projects/${repo_name}
# }

function repoCleanup() {
	local repo_name=$1
	local organization=$2
	if [ ! -d "repo-projects/${repo_name}" ]; then
    		git clone git@github.com:${organization}/${repo_name}.git repo-projects/${repo_name}
	else
    		echo "Repo ${repo_name} already exists, skipping clone"
        fi
	# git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
	printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
	# git checkout $ORIGIN_BRANCH
	# git branch -D $TARGET_BRANCH
	pushd repo-projects/${repo_name}
	git remote update --prune
	git reset --hard HEAD
	[ ! -z "{ORIGIN_BRANCH:-}" ] && git checkout $ORIGIN_BRANCH || git checkout $DEFAULT_BRANCH
	git reset --hard HEAD
	git pull
	printf "\e[1;33m# %s\e[m\n" "Testing if ${TARGET_BRANCH} branch doesn't already exists and reuse it ($repo_name) ..."
	set +e
	GIT_PUSH_PARAMS=""
	git checkout $TARGET_BRANCH
	if [ "$?" -ne "0" ]; then
		git checkout -b $TARGET_BRANCH
	else
		printf "\e[1;35m# %s\e[m\n" "WARNING : the ${TARGET_BRANCH} branch already exists so we will delete it (you have 5 seconds to cancel with CTRL+C) ($repo_name) ..."
		# sleep 5
		[ ! -z "{ORIGIN_BRANCH:-}" ] && git checkout $ORIGIN_BRANCH || git checkout $DEFAULT_BRANCH
		git branch -D $TARGET_BRANCH
		git checkout -b $TARGET_BRANCH
		GIT_PUSH_PARAMS="--force"
	fi
}

function replaceProjectVersion() {
	local repo_name=$1
	printf "\e[1;33m# %s\e[m\n" "Modifying versions in the project POMs ($repo_name) ..."
	set -e
	case $repo_name in	
	addons-manager) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_MANAGER_ORIGIN_VERSION</version>" "<version>$ADDONS_MANAGER_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	agenda) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_AGENDA_ORIGIN_VERSION</version>" "<version>$ADDONS_AGENDA_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	analytics) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_ANALYTICS_ORIGIN_VERSION</version>" "<version>$ADDONS_ANALYTICS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	poll) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_POLL_ORIGIN_VERSION</version>" "<version>$ADDONS_POLL_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	app-center) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_APP_CENTER_ORIGIN_VERSION</version>" "<version>$ADDON_APP_CENTER_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	chat-application) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_CHAT_ORIGIN_VERSION</version>" "<version>$ADDON_CHAT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	digital-workplace) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_DIGITAL_WORKPLACE_ORIGIN_VERSION</version>" "<version>$ADDON_DIGITAL_WORKPLACE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	gamification) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_GAMIFICATION_ORIGIN_VERSION</version>" "<version>$ADDON_GAMIFICATION_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	jitsi) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_JITSI_ORIGIN_VERSION</version>" "<version>$ADDONS_JITSI_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	jitsi-call) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_JITSI_ORIGIN_VERSION</version>" "<version>$ADDONS_JITSI_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	multifactor-authentication) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_MULTIFACTOR_AUTHENTICATION_ORIGIN_VERSION</version>" "<version>$ADDONS_MULTIFACTOR_AUTHENTICATION_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	kudos) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_KUDOS_ORIGIN_VERSION</version>" "<version>$ADDON_KUDOS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	layout-management) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_LAYOUT_MANAGEMENT_ORIGIN_VERSION</version>" "<version>$ADDON_LAYOUT_MANAGEMENT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	news) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_NEWS_ORIGIN_VERSION</version>" "<version>$ADDON_NEWS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	maven-depmgt-pom) $SCRIPTDIR/../replaceInFile.sh "<version>$DEPMGT_ORIGIN_VERSION</version>" "<version>$DEPMGT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	onlyoffice) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_ONLYOFFICE_ORIGIN_VERSION</version>" "<version>$ADDON_ONLYOFFICE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	perk-store) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_PERK_STORE_ORIGIN_VERSION</version>" "<version>$ADDON_PERK_STORE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	push-notifications) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION</version>" "<version>$ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	saml2-addon) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_SAML2_ORIGIN_VERSION</version>" "<version>$ADDON_SAML2_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	task) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_TASK_ORIGIN_VERSION</version>" "<version>$ADDON_TASK_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	wallet) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_WALLET_ORIGIN_VERSION</version>" "<version>$ADDON_WALLET_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	web-conferencing) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_WEB_CONFERENCING_ORIGIN_VERSION</version>" "<version>$ADDON_WEB_CONFERENCING_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	data-upgrade) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_DATA_UPGRADE_ORIGIN_VERSION</version>" "<version>$ADDONS_DATA_UPGRADE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	meeds) $SCRIPTDIR/../replaceInFile.sh "<version>$MEEDS_ORIGIN_VERSION</version>" "<version>$MEEDS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	automatic-translation) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_AUTOMATIC_TRANSLATION_ORIGIN_VERSION</version>" "<version>$ADDONS_AUTOMATIC_TRANSLATION_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	documents) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_DOCUMENTS_ORIGIN_VERSION</version>" "<version>$ADDONS_DOCUMENTS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;	
	processes) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_PROCESSES_ORIGIN_VERSION</version>" "<version>$ADDONS_PROCESSES_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	mail-integration) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_MAIL_INTEGRATION_ORIGIN_VERSION</version>" "<version>$ADDONS_MAIL_INTEGRATION_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	gamification-github) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_GAMIFICATION_GITHUB_ORIGIN_VERSION</version>" "<version>$ADDONS_GAMIFICATION_GITHUB_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	anti-bruteforce) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_ANTI_BRUTEFORCE_ORIGIN_VERSION</version>" "<version>$ADDONS_ANTI_BRUTEFORCE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	anti-malware) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_ANTI_MALWARE_ORIGIN_VERSION</version>" "<version>$ADDONS_ANTI_MALWARE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	dlp) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_DLP_ORIGIN_VERSION</version>" "<version>$ADDONS_DLP_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	agenda-connectors) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDONS_AGENDA_CONNECTORS_ORIGIN_VERSION</version>" "<version>$ADDONS_AGENDA_CONNECTORS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	*) $SCRIPTDIR/../replaceInFile.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	esac
}

function replaceProjectDeps() {
	printf "\e[1;33m# %s\e[m\n" "Modifying dependencies versions in the project POMs ($repo_name) ..."

	## GateIn WCI
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.gatein.wci.version>$ORIGIN_VERSION</org.exoplatform.gatein.wci.version>" "<org.exoplatform.gatein.wci.version>$TARGET_VERSION</org.exoplatform.gatein.wci.version>" "pom.xml -not -wholename \"*/target/*\""

	## CF
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.kernel.version>$ORIGIN_VERSION</org.exoplatform.kernel.version>" "<org.exoplatform.kernel.version>$TARGET_VERSION</org.exoplatform.kernel.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.core.version>$ORIGIN_VERSION</org.exoplatform.core.version>" "<org.exoplatform.core.version>$TARGET_VERSION</org.exoplatform.core.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.ws.version>$ORIGIN_VERSION</org.exoplatform.ws.version>" "<org.exoplatform.ws.version>$TARGET_VERSION</org.exoplatform.ws.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.jcr-services.version>$ORIGIN_VERSION</org.exoplatform.jcr-services.version>" "<org.exoplatform.jcr-services.version>$TARGET_VERSION</org.exoplatform.jcr-services.version>" "pom.xml -not -wholename \"*/target/*\""

	## GateIn
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.gatein.sso.version>$ORIGIN_VERSION</org.exoplatform.gatein.sso.version>" "<org.exoplatform.gatein.sso.version>$TARGET_VERSION</org.exoplatform.gatein.sso.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.gatein.pc.version>$ORIGIN_VERSION</org.exoplatform.gatein.pc.version>" "<org.exoplatform.gatein.pc.version>$TARGET_VERSION</org.exoplatform.gatein.pc.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.gatein.portal.version>$ORIGIN_VERSION</org.exoplatform.gatein.portal.version>" "<org.exoplatform.gatein.portal.version>$TARGET_VERSION</org.exoplatform.gatein.portal.version>" "pom.xml -not -wholename \"*/target/*\""

	## PLF
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.depmgt.version>$DEPMGT_ORIGIN_VERSION</org.exoplatform.depmgt.version>" "<org.exoplatform.depmgt.version>$DEPMGT_TARGET_VERSION</org.exoplatform.depmgt.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_VERSION</org.exoplatform.platform-ui.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_VERSION</org.exoplatform.commons.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_VERSION</org.exoplatform.ecms.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.jcr.version>$ORIGIN_VERSION</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>$TARGET_VERSION</org.exoplatform.jcr.version>" "pom.xml -not -wholename \"*/target/*\""

	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_VERSION</org.exoplatform.social.version>" "pom.xml -not -wholename \"*/target/*\""	
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.notes.version>$ADDONS_NOTES_ORIGIN_VERSION</addon.exo.notes.version>" "<addon.exo.notes.version>$ADDONS_NOTES_TARGET_VERSION</addon.exo.notes.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.agenda.version>$ADDONS_AGENDA_ORIGIN_VERSION</org.exoplatform.agenda.version>" "<org.exoplatform.agenda.version>$ADDONS_AGENDA_TARGET_VERSION</org.exoplatform.agenda.version>" "pom.xml -not -wholename \"*/target/*\""	
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.distribution.version>$MEEDS_ORIGIN_VERSION</io.meeds.distribution.version>" "<io.meeds.distribution.version>$MEEDS_TARGET_VERSION</io.meeds.distribution.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_VERSION</org.exoplatform.platform.distributions.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform.addons-manager.version>$ADDONS_MANAGER_ORIGIN_VERSION</org.exoplatform.platform.addons-manager.version>" "<org.exoplatform.platform.addons-manager.version>$ADDONS_MANAGER_TARGET_VERSION</org.exoplatform.platform.addons-manager.version>" "pom.xml -not -wholename \"*/target/*\""
}

function replaceProjectAddons() {
	printf "\e[1;33m# %s\e[m\n" "Modifying add-ons versions in the packaging project POMs ($repo_name) ..."

	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.app-center.version>$ADDON_APP_CENTER_ORIGIN_VERSION</addon.exo.app-center.version>" "<addon.exo.app-center.version>$ADDON_APP_CENTER_TARGET_VERSION</addon.exo.app-center.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.chat.version>$ADDON_CHAT_ORIGIN_VERSION</addon.exo.chat.version>" "<addon.exo.chat.version>$ADDON_CHAT_TARGET_VERSION</addon.exo.chat.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.digital-workplace.version>$ADDON_DIGITAL_WORKPLACE_ORIGIN_VERSION</addon.exo.digital-workplace.version>" "<addon.exo.digital-workplace.version>$ADDON_DIGITAL_WORKPLACE_TARGET_VERSION</addon.exo.digital-workplace.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.ecms.version>$ORIGIN_VERSION</addon.exo.ecms.version>" "<addon.exo.ecms.version>$TARGET_VERSION</addon.exo.ecms.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.gamification.version>$ADDON_GAMIFICATION_ORIGIN_VERSION</addon.exo.gamification.version>" "<addon.exo.gamification.version>$ADDON_GAMIFICATION_TARGET_VERSION</addon.exo.gamification.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.jcr.version>$ORIGIN_VERSION</addon.exo.jcr.version>" "<addon.exo.jcr.version>$TARGET_VERSION</addon.exo.jcr.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.kudos.version>$ADDON_KUDOS_ORIGIN_VERSION</addon.exo.kudos.version>" "<addon.exo.kudos.version>$ADDON_KUDOS_TARGET_VERSION</addon.exo.kudos.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.layout-management.version>$ADDON_LAYOUT_MANAGEMENT_ORIGIN_VERSION</addon.exo.layout-management.version>" "<addon.exo.layout-management.version>$ADDON_LAYOUT_MANAGEMENT_TARGET_VERSION</addon.exo.layout-management.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.onlyoffice.version>$ADDON_ONLYOFFICE_ORIGIN_VERSION</addon.exo.onlyffice.version>" "<addon.exo.onlyoffice.version>$ADDON_ONLYOFFICE_TARGET_VERSION</addon.exo.onlyoffice.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.perk-store.version>$ADDON_PERK_STORE_ORIGIN_VERSION</addon.exo.perk-store.version>" "<addon.exo.perk-store.version>$ADDON_PERK_STORE_TARGET_VERSION</addon.exo.perk-store.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.push-notifications.version>$ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION</addon.exo.push-notifications.version>" "<addon.exo.push-notifications.version>$ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION</addon.exo.push-notifications.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.saml2-addon.version>$ADDON_SAML2_ORIGIN_VERSION</addon.exo.saml2-addon.version>" "<addon.exo.saml2-addon.version>$ADDON_SAML2_TARGET_VERSION</addon.exo.saml2-addon.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.tasks.version>$ADDON_TASK_ORIGIN_VERSION</addon.exo.tasks.version>" "<addon.exo.tasks.version>$ADDON_TASK_TARGET_VERSION</addon.exo.tasks.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.wallet.version>$ADDON_WALLET_ORIGIN_VERSION</addon.exo.wallet.version>" "<addon.exo.wallet.version>$ADDON_WALLET_TARGET_VERSION</addon.exo.wallet.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.web-conferencing.version>$ADDON_WEB_CONFERENCING_ORIGIN_VERSION</addon.exo.web-conferencing.version>" "<addon.exo.web-conferencing.version>$ADDON_WEB_CONFERENCING_TARGET_VERSION</addon.exo.web-conferencing.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.data-upgrade.version>$ADDONS_DATA_UPGRADE_ORIGIN_VERSION</addon.exo.data-upgrade.version>" "<addon.exo.data-upgrade.version>$ADDONS_DATA_UPGRADE_TARGET_VERSION</addon.exo.data-upgrade.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.analytics.version>$ADDONS_ANALYTICS_ORIGIN_VERSION</addon.exo.analytics.version>" "<addon.exo.analytics.version>$ADDONS_ANALYTICS_TARGET_VERSION</addon.exo.analytics.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.jitsi.version>$ADDONS_JITSI_ORIGIN_VERSION</org.exoplatform.jitsi.version>" "<addon.exo.jitsi.version>$ADDONS_JITSI_TARGET_VERSION</addon.exo.jitsi.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.jitsi-call.version>$ADDONS_JITSI_ORIGIN_VERSION</org.exoplatform.jitsi-call.version>" "<addon.exo.jitsi-call.version>$ADDONS_JITSI_TARGET_VERSION</addon.exo.jitsi-call.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.multifactor-authentication.version>$ADDONS_MULTIFACTOR_AUTHENTICATION_ORIGIN_VERSION</addon.exo.multifactor-authentication.version>" "<addon.exo.multifactor-authentication.version>$ADDONS_MULTIFACTOR_AUTHENTICATION_TARGET_VERSION</addon.exo.multifactor-authentication.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.notes.version>$ADDONS_NOTES_ORIGIN_VERSION</addon.exo.notes.version>" "<addon.exo.notes.version>$ADDONS_NOTES_TARGET_VERSION</addon.exo.notes.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.documents.version>$ADDONS_DOCUMENTS_ORIGIN_VERSION</addon.exo.documents.version>" "<addon.exo.documents.version>$ADDONS_DOCUMENTS_TARGET_VERSION</addon.exo.documents.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.processes.version>$ADDONS_PROCESSES_ORIGIN_VERSION</addon.exo.processes.version>" "<addon.exo.processes.version>$ADDONS_PROCESSES_TARGET_VERSION</addon.exo.processes.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.poll.version>$ADDONS_POLL_ORIGIN_VERSION</addon.exo.poll.version>" "<addon.exo.poll.version>$ADDONS_POLL_TARGET_VERSION</addon.exo.poll.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.automatic-translation.version>$ADDONS_AUTOMATIC_TRANSLATION_ORIGIN_VERSION</addon.exo.automatic-translation.version>" "<addon.exo.automatic-translation.version>$ADDONS_AUTOMATIC_TRANSLATION_TARGET_VERSION</addon.exo.automatic-translation.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.mail-integration.version>$ADDONS_MAIL_INTEGRATION_ORIGIN_VERSION</addon.exo.mail-integration.version>" "<addon.exo.mail-integration.version>$ADDONS_MAIL_INTEGRATION_TARGET_VERSION</addon.exo.mail-integration.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.gamification-github.version>$ADDONS_GAMIFICATION_GITHUB_ORIGIN_VERSION</addon.meeds.gamification-github.version>" "<addon.meeds.gamification-github.version>$ADDONS_GAMIFICATION_GITHUB_TARGET_VERSION</addon.meeds.gamification-github.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.anti-bruteforce.version>$ADDONS_ANTI_BRUTEFORCE_ORIGIN_VERSION</addon.exo.anti-bruteforce.version>" "<addon.exo.anti-bruteforce.version>$ADDONS_ANTI_BRUTEFORCE_TARGET_VERSION</addon.exo.anti-bruteforce.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.anti-malware.version>$ADDONS_ANTI_MALWARE_ORIGIN_VERSION</addon.exo.anti-malware.version>" "<addon.exo.anti-malware.version>$ADDONS_ANTI_MALWARE_TARGET_VERSION</addon.exo.anti-malware.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.dlp.version>$ADDONS_DLP_ORIGIN_VERSION</addon.exo.dlp.version>" "<addon.exo.dlp.version>$ADDONS_DLP_TARGET_VERSION</addon.exo.dlp.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.agenda-connectors.version>$ADDONS_AGENDA_CONNECTORS_ORIGIN_VERSION</addon.exo.agenda-connectors.version>" "<addon.exo.agenda-connectors.version>$ADDONS_AGENDA_CONNECTORS_TARGET_VERSION</addon.exo.agenda-connectors.version>" "pom.xml -not -wholename \"*/target/*\""
}

function createFB() {
	local repo_name=$1
	local organization=$2
    
	repoCleanup ${repo_name} ${organization}

	replaceProjectVersion ${repo_name}
	replaceProjectDeps ${repo_name}
	replaceProjectAddons ${repo_name}

	# Replace add-on versions in distributions project
	# case $repo_name in
	# *-distributions) replaceProjectAddons ${repo_name} ;;
	# esac

	printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ($repo_name) ..."
	git commit -m "$ISSUE: Create FB $BRANCH and update projects versions/dependencies" -a
	# git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream

	if $PUSH; then
		printf "\e[1;33m# %s\e[m\n" "Pushing commit to ${TARGET_BRANCH} ..."
		git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream
		# Return on dev branch only in real runs to easily debug during test phase
		[ ! -z "{ORIGIN_BRANCH:-}" ] && git checkout $ORIGIN_BRANCH || git checkout $DEFAULT_BRANCH
	else
		printf "\e[1;35m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;33m# %s\e[m\n" "Following command would have been executed : |git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream|"
	fi

	popd
}

pushd ${SWF_FB_REPOS}
echo "==================================="
echo "SWF_FB_REPOS : ${SWF_FB_REPOS}"
echo "==================================="

#Meeds Projects
createFB gatein-wci Meeds-io
createFB kernel Meeds-io
createFB core Meeds-io
createFB ws Meeds-io
createFB gatein-pc Meeds-io
createFB gatein-sso Meeds-io
createFB gatein-portal Meeds-io
createFB maven-depmgt-pom Meeds-io
createFB platform-ui Meeds-io
createFB commons Meeds-io
createFB social Meeds-io
createFB addons-manager Meeds-io
createFB app-center Meeds-io
createFB gamification Meeds-io
createFB kudos Meeds-io
createFB perk-store Meeds-io
createFB wallet Meeds-io
createFB meeds Meeds-io
createFB push-notifications Meeds-io
createFB notes Meeds-io
createFB analytics Meeds-io
createFB task Meeds-io
createFB poll Meeds-io
createFB gamification-github Meeds-io

# # Explatform projects
createFB ecms exoplatform
createFB jcr exoplatform
createFB agenda exoplatform
createFB jitsi exoplatform
createFB jitsi-call exoplatform
createFB chat-application exoplatform
createFB multifactor-authentication exoplatform
createFB digital-workplace exoplatform
createFB layout-management exoplatform
createFB news exoplatform
createFB onlyoffice exoplatform
createFB saml2-addon exoplatform
createFB web-conferencing exoplatform
createFB data-upgrade exoplatform
createFB platform-private-distributions exoplatform
createFB automatic-translation exoplatform
createFB processes exoplatform
createFB documents exoplatform
createFB mail-integration exoplatform
createFB anti-bruteforce exoplatform
createFB anti-malware exoplatform
createFB dlp exoplatform
createFB agenda-connectors exoplatform
popd

echo
printf "\e[1;33m# %s\e[m\n" "Feature branch ${BRANCH} created"
