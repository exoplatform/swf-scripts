#!/bin/bash -eu

# Create Git Feature Branches for PLF projects

BRANCH=meeds
ISSUE=ITOP-4645
ORIGIN_BRANCH=develop
TARGET_BRANCH=feature/$BRANCH
ORIGIN_VERSION=6.0.x-SNAPSHOT
TARGET_VERSION=6.0.x-$BRANCH-SNAPSHOT
# Maven DEPMGT
DEPMGT_ORIGIN_VERSION=17.x-SNAPSHOT
DEPMGT_TARGET_VERSION=17.x-$BRANCH-SNAPSHOT
# GateIn DEPMGT
GATEIN_DEP_ORIGIN_VERSION=2.0.x-SNAPSHOT
GATEIN_DEP_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Cas
ADDON_CAS_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_CAS_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Chat
ADDON_CHAT_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_CHAT_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on DW Homepage
ADDON_DIGITAL_WORKPLACE_ORIGIN_VERSION=1.0.x-SNAPSHOT
ADDON_DIGITAL_WORKPLACE_TARGET_VERSION=1.0.x-$BRANCH-SNAPSHOT
# Add-on eXo ElasticSearch Embedded
ADDON_ES_EMBED_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_ES_EMBED_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Gamification
ADDON_GAMIFICATION_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_GAMIFICATION_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Kudos
ADDON_KUDOS_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_KUDOS_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Layout Management
ADDON_LAYOUT_MANAGEMENT_ORIGIN_VERSION=1.0.x-SNAPSHOT
ADDON_LAYOUT_MANAGEMENT_TARGET_VERSION=1.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Lecko
ADDON_LECKO_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_LECKO_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo news
ADDON_NEWS_ORIGIN_VERSION=1.1.x-SNAPSHOT
ADDON_NEWS_TARGET_VERSION=1.1.x-$BRANCH-SNAPSHOT
# Add-on eXo Openam
ADDON_OPENAM_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_OPENAM_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Remote Edit
ADDON_REMOTE_EDIT_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_REMOTE_EDIT_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Perk Store
ADDON_PERK_STORE_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_PERK_STORE_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo OnlyOffice
ADDON_ONLYOFFICE_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_ONLYOFFICE_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Push notifications
ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo saml2
ADDON_SAML2_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_SAML2_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo spnego
ADDON_SPNEGO_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_SPNEGO_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Task
ADDON_TASK_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_TASK_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on Wallet
ADDON_WALLET_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_WALLET_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Web Conferencing
ADDON_WEB_CONFERENCING_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_WEB_CONFERENCING_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT
# Add-on eXo Web Pack
ADDON_WEB_PACK_ORIGIN_VERSION=3.0.x-SNAPSHOT
ADDON_WEB_PACK_TARGET_VERSION=3.0.x-$BRANCH-SNAPSHOT
# Add-on eXo App Center
ADDON_APP_CENTER_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDON_APP_CENTER_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT

# Add-on manager
ADDONS_MANAGER_ORIGIN_VERSION=2.0.x-SNAPSHOT
ADDONS_MANAGER_TARGET_VERSION=2.0.x-$BRANCH-SNAPSHOT

SCRIPTDIR=$(
	cd $(dirname "$0")
	pwd
)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}

PUSH=false

while getopts "p" opt; do
	case $opt in
	p)
		PUSH=true
		;;
	esac
done

function repoInit() {
	local repo_name=$1
	printf "\e[1;33m########################################\e[m\n"
	printf "\e[1;33m# Repository: %s\e[m\n" "${repo_name}"
	printf "\e[1;33m########################################\e[m\n"
	pushd ${repo_name}
}

function repoCleanup() {
	local repo_name=$1
	# git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
	printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
	# git checkout $ORIGIN_BRANCH
	# git branch -D $TARGET_BRANCH
	git remote update --prune
	git reset --hard HEAD
	git checkout $ORIGIN_BRANCH
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
		git checkout $ORIGIN_BRANCH
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
	answers) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_ANSWERS_ORIGIN_VERSION</version>" "<version>$ADDON_ANSWERS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	app-center) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_APP_CENTER_ORIGIN_VERSION</version>" "<version>$ADDON_APP_CENTER_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	cas-addon) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_CAS_ORIGIN_VERSION</version>" "<version>$ADDON_CAS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	chat-application) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_CHAT_ORIGIN_VERSION</version>" "<version>$ADDON_CHAT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	exo-es-embedded) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_ES_EMBED_ORIGIN_VERSION</version>" "<version>$ADDON_ES_EMBED_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	digital-workplace) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_DIGITAL_WORKPLACE_ORIGIN_VERSION</version>" "<version>$ADDON_DIGITAL_WORKPLACE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	gatein-dep) $SCRIPTDIR/../replaceInFile.sh "<version>$GATEIN_DEP_ORIGIN_VERSION</version>" "<version>$GATEIN_DEP_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	gamification) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_GAMIFICATION_ORIGIN_VERSION</version>" "<version>$ADDON_GAMIFICATION_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	kudos) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_KUDOS_ORIGIN_VERSION</version>" "<version>$ADDON_KUDOS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	layout-management) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_LAYOUT_MANAGEMENT_ORIGIN_VERSION</version>" "<version>$ADDON_LAYOUT_MANAGEMENT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	lecko) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_LECKO_ORIGIN_VERSION</version>" "<version>$ADDON_LECKO_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	news) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_NEWS_ORIGIN_VERSION</version>" "<version>$ADDON_NEWS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	maven-depmgt-pom) $SCRIPTDIR/../replaceInFile.sh "<version>$DEPMGT_ORIGIN_VERSION</version>" "<version>$DEPMGT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	onlyoffice) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_ONLYOFFICE_ORIGIN_VERSION</version>" "<version>$ADDON_ONLYOFFICE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	openam-addon) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_OPENAM_ORIGIN_VERSION</version>" "<version>$ADDON_OPENAM_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	perk-store) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_PERK_STORE_ORIGIN_VERSION</version>" "<version>$ADDON_PERK_STORE_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	push-notifications) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION</version>" "<version>$ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	remote-edit) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_REMOTE_EDIT_ORIGIN_VERSION</version>" "<version>$ADDON_REMOTE_EDIT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	saml2-addon) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_SAML2_ORIGIN_VERSION</version>" "<version>$ADDON_SAML2_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	spnego-addon) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_SPNEGO_ORIGIN_VERSION</version>" "<version>$ADDON_SPNEGO_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	task) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_TASK_ORIGIN_VERSION</version>" "<version>$ADDON_TASK_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	wcm-template-pack) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_WEB_PACK_ORIGIN_VERSION</version>" "<version>$ADDON_WEB_PACK_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	wallet) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_WALLET_ORIGIN_VERSION</version>" "<version>$ADDON_WALLET_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	web-conferencing) $SCRIPTDIR/../replaceInFile.sh "<version>$ADDON_WEB_CONFERENCING_ORIGIN_VERSION</version>" "<version>$ADDON_WEB_CONFERENCING_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	*) $SCRIPTDIR/../replaceInFile.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
	esac
}

function replaceProjectDeps() {
	printf "\e[1;33m# %s\e[m\n" "Modifying dependencies versions in the project POMs ($repo_name) ..."

	## GateIn Dep
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.gatein.dep.version>$GATEIN_DEP_ORIGIN_VERSION</org.exoplatform.gatein.dep.version>" "<org.exoplatform.gatein.dep.version>$GATEIN_DEP_TARGET_VERSION</org.exoplatform.gatein.dep.version>" "pom.xml -not -wholename \"*/target/*\""

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
	# $SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.doc.doc-style.version>$ORIGIN_VERSION</org.exoplatform.doc.doc-style.version>" "<org.exoplatform.doc.doc-style.version>$TARGET_VERSION</org.exoplatform.doc.doc-style.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform-ui.version>$ORIGIN_VERSION</org.exoplatform.platform-ui.version>" "<org.exoplatform.platform-ui.version>$TARGET_VERSION</org.exoplatform.platform-ui.version>" "pom.xml -not -wholename \"*/target/*\""
	# Temporary after lightweight merge
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.calendar.version>$ORIGIN_VERSION</org.exoplatform.calendar.version>" "<org.exoplatform.calendar.version>$TARGET_VERSION</org.exoplatform.calendar.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.commons.version>$ORIGIN_VERSION</org.exoplatform.commons.version>" "<org.exoplatform.commons.version>$TARGET_VERSION</org.exoplatform.commons.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.ecms.version>$ORIGIN_VERSION</org.exoplatform.ecms.version>" "<org.exoplatform.ecms.version>$TARGET_VERSION</org.exoplatform.ecms.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.jcr.version>$ORIGIN_VERSION</org.exoplatform.jcr.version>" "<org.exoplatform.jcr.version>$TARGET_VERSION</org.exoplatform.jcr.version>" "pom.xml -not -wholename \"*/target/*\""

	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.social.version>$ORIGIN_VERSION</org.exoplatform.social.version>" "<org.exoplatform.social.version>$TARGET_VERSION</org.exoplatform.social.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.wiki.version>$ORIGIN_VERSION</org.exoplatform.wiki.version>" "<org.exoplatform.wiki.version>$TARGET_VERSION</org.exoplatform.wiki.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.forum.version>$ORIGIN_VERSION</org.exoplatform.forum.version>" "<org.exoplatform.forum.version>$TARGET_VERSION</org.exoplatform.forum.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.integ.version>$ORIGIN_VERSION</org.exoplatform.integ.version>" "<org.exoplatform.integ.version>$TARGET_VERSION</org.exoplatform.integ.version>" "pom.xml -not -wholename \"*/target/*\""
	# $SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform.version>$ORIGIN_VERSION</org.exoplatform.platform.version>" "<org.exoplatform.platform.version>$TARGET_VERSION</org.exoplatform.platform.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform.distributions.version>$ORIGIN_VERSION</org.exoplatform.platform.distributions.version>" "<org.exoplatform.platform.distributions.version>$TARGET_VERSION</org.exoplatform.platform.distributions.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.platform.addons-manager.version>$ADDONS_MANAGER_ORIGIN_VERSION</org.exoplatform.platform.addons-manager.version>" "<org.exoplatform.platform.addons-manager.version>$ADDONS_MANAGER_TARGET_VERSION</org.exoplatform.platform.addons-manager.version>" "pom.xml -not -wholename \"*/target/*\""
}

function replaceProjectAddons() {
	printf "\e[1;33m# %s\e[m\n" "Modifying add-ons versions in the packaging project POMs ($repo_name) ..."

	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.es.embedded.version>$ADDON_ES_EMBED_ORIGIN_VERSION</addon.exo.es.embedded.version>" "<addon.exo.es.embedded.version>$ADDON_ES_EMBED_TARGET_VERSION</addon.exo.es.embedded.version>" "pom.xml -not -wholename \"*/target/*\""
	#	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.answers.version>$ADDON_ANSWERS_ORIGIN_VERSION</addon.exo.answers.version>" "<addon.exo.answers.version>$ADDON_ANSWERS_TARGET_VERSION</addon.exo.answers.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.app-center.version>$ADDON_APP_CENTER_ORIGIN_VERSION</addon.exo.app-center.version>" "<addon.exo.app-center.version>$ADDON_APP_CENTER_TARGET_VERSION</addon.exo.app-center.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.calendar.version>$ORIGIN_VERSION</addon.exo.calendar.version>" "<addon.exo.calendar.version>$TARGET_VERSION</addon.exo.calendar.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.cas-addon.version>$ADDON_CAS_ORIGIN_VERSION</addon.exo.cas-addon.version>" "<addon.exo.cas-addon.version>$ADDON_CAS_TARGET_VERSION</addon.exo.cas-addon.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.chat.version>$ADDON_CHAT_ORIGIN_VERSION</addon.exo.chat.version>" "<addon.exo.chat.version>$ADDON_CHAT_TARGET_VERSION</addon.exo.chat.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.digital-workplace.version>$ADDON_DIGITAL_WORKPLACE_ORIGIN_VERSION</addon.exo.digital-workplace.version>" "<addon.exo.digital-workplace.version>$ADDON_DIGITAL_WORKPLACE_TARGET_VERSION</addon.exo.digital-workplace.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.ecms.version>$ORIGIN_VERSION</addon.exo.ecms.version>" "<addon.exo.ecms.version>$TARGET_VERSION</addon.exo.ecms.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.enterprise-skin.version>$ORIGIN_VERSION</addon.exo.enterprise-skin.version>" "<addon.exo.enterprise-skin.version>$TARGET_VERSION</addon.exo.enterprise-skin.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.gamification.version>$ADDON_GAMIFICATION_ORIGIN_VERSION</addon.exo.gamification.version>" "<addon.exo.gamification.version>$ADDON_GAMIFICATION_TARGET_VERSION</addon.exo.gamification.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.jcr.version>$ORIGIN_VERSION</addon.exo.jcr.version>" "<addon.exo.jcr.version>$TARGET_VERSION</addon.exo.jcr.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.kudos.version>$ADDON_KUDOS_ORIGIN_VERSION</addon.exo.kudos.version>" "<addon.exo.kudos.version>$ADDON_KUDOS_TARGET_VERSION</addon.exo.kudos.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.layout-management.version>$ADDON_LAYOUT_MANAGEMENT_ORIGIN_VERSION</addon.exo.layout-management.version>" "<addon.exo.layout-management.version>$ADDON_LAYOUT_MANAGEMENT_TARGET_VERSION</addon.exo.layout-management.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.lecko.version>$ADDON_LECKO_ORIGIN_VERSION</addon.exo.lecko.version>" "<addon.exo.lecko.version>$ADDON_LECKO_TARGET_VERSION</addon.exo.lecko.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.onlyoffice.version>$ADDON_ONLYOFFICE_ORIGIN_VERSION</addon.exo.onlyffice.version>" "<addon.exo.onlyoffice.version>$ADDON_ONLYOFFICE_TARGET_VERSION</addon.exo.onlyoffice.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.openam-addon.version>$ADDON_OPENAM_ORIGIN_VERSION</addon.exo.openam-addon.version>" "<addon.exo.openam-addon.version>$ADDON_OPENAM_TARGET_VERSION</addon.exo.openam-addon.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.perk-store.version>$ADDON_PERK_STORE_ORIGIN_VERSION</addon.exo.perk-store.version>" "<addon.exo.perk-store.version>$ADDON_PERK_STORE_TARGET_VERSION</addon.exo.perk-store.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.push-notifications.version>$ADDON_PUSH_NOTIFICATIONS_ORIGIN_VERSION</addon.exo.push-notifications.version>" "<addon.exo.push-notifications.version>$ADDON_PUSH_NOTIFICATIONS_TARGET_VERSION</addon.exo.push-notifications.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.remote-edit.version>$ADDON_REMOTE_EDIT_ORIGIN_VERSION</addon.exo.remote-edit.version>" "<addon.exo.remote-edit.version>$ADDON_REMOTE_EDIT_TARGET_VERSION</addon.exo.remote-edit.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.saml2-addon.version>$ADDON_SAML2_ORIGIN_VERSION</addon.exo.saml2-addon.version>" "<addon.exo.saml2-addon.version>$ADDON_SAML2_TARGET_VERSION</addon.exo.saml2-addon.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.spnego-addon.version>$ADDON_SPNEGO_ORIGIN_VERSION</addon.exo.spnego-addon.version>" "<addon.exo.spnego-addon.version>$ADDON_SPNEGO_TARGET_VERSION</addon.exo.spnego-addon.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.tasks.version>$ADDON_TASK_ORIGIN_VERSION</addon.exo.tasks.version>" "<addon.exo.tasks.version>$ADDON_TASK_TARGET_VERSION</addon.exo.tasks.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.wallet.version>$ADDON_WALLET_ORIGIN_VERSION</addon.exo.wallet.version>" "<addon.exo.wallet.version>$ADDON_WALLET_TARGET_VERSION</addon.exo.wallet.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.web-pack.version>$ADDON_WEB_PACK_ORIGIN_VERSION</addon.exo.web-pack.version>" "<addon.exo.web-pack.version>$ADDON_WEB_PACK_TARGET_VERSION</addon.exo.web-pack.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.web-conferencing.version>$ADDON_WEB_CONFERENCING_ORIGIN_VERSION</addon.exo.web-conferencing.version>" "<addon.exo.web-conferencing.version>$ADDON_WEB_CONFERENCING_TARGET_VERSION</addon.exo.web-conferencing.version>" "pom.xml -not -wholename \"*/target/*\""
}

function createFB() {
	local repo_name=$1

	repoInit ${repo_name}
	# Remove all branches but the origin one
	repoCleanup ${repo_name}

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
		git checkout ${ORIGIN_BRANCH}
	else
		printf "\e[1;35m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;33m# %s\e[m\n" "Following command would have been executed : |git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream|"
	fi

	popd
}

pushd ${SWF_FB_REPOS}

createFB gatein-dep
createFB gatein-wci
createFB kernel
createFB core
createFB ws
createFB gatein-pc
createFB gatein-sso
createFB gatein-portal
createFB maven-depmgt-pom
# Removed on lightweight
# createFB docs-style
createFB platform-ui
createFB commons
createFB social
# Removed on lightweight
# createFB integration
# Removed on lightweight
# createFB platform

# CE plugins
createFB ecms
createFB jcr
createFB wiki
createFB forum
createFB calendar


createFB addons-manager
createFB app-center
createFB cas-addon
createFB chat-application
createFB cmis-addon
createFB data-upgrade
createFB digital-workplace
createFB enterprise-skin
createFB exo-es-embedded
createFB gamification
createFB kudos
createFB layout-management
createFB lecko
createFB legacy-intranet
createFB news
createFB onlyoffice
createFB openam-addon
createFB perk-store
createFB push-notifications
createFB remote-edit
createFB saml2-addon
createFB spnego-addon
createFB task
createFB wallet
createFB wcm-template-pack
createFB web-conferencing

createFB platform-public-distributions
createFB platform-private-distributions
popd

echo
printf "\e[1;33m# %s\e[m\n" "Feature branch ${BRANCH} created"
