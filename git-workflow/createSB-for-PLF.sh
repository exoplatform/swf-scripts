#!/bin/bash -eu

ISSUE=ITOP-4722
CURRENT_DEVELOP_VERSION_PREFIX=6.0.x
NEXT_DEVELOP_VERSION_PREFIX=6.1.x

CURRENT_DEVELOP_VERSION=${CURRENT_DEVELOP_VERSION_PREFIX}-SNAPSHOT
NEXT_DEVELOP_VERSION=${NEXT_DEVELOP_VERSION_PREFIX}-SNAPSHOT

JUZU_CURRENT_VERSION_PREFIX=1.2.0
JUZU_NEXT_VERSION_PREFIX=1.2.0
JUZU_CURRENT_DEVELOP_VERSION=${JUZU_CURRENT_VERSION_PREFIX}-SNAPSHOT
JUZU_NEXT_DEVELOP_VERSION=${JUZU_NEXT_VERSION_PREFIX}-SNAPSHOT

GATEIN_DEP_CURRENT_VERSION_PREFIX=2.0.x
GATEIN_DEP_NEXT_VERSION_PREFIX=2.1.x
GATEIN_DEP_CURRENT_DEVELOP_VERSION=${GATEIN_DEP_CURRENT_VERSION_PREFIX}-SNAPSHOT
GATEIN_DEP_NEXT_DEVELOP_VERSION=${GATEIN_DEP_NEXT_VERSION_PREFIX}-SNAPSHOT

MAVEN_DEPMGT_CURRENT_VERSION_PREFIX=17.x
MAVEN_DEPMGT_NEXT_VERSION_PREFIX=18.x
MAVEN_DEPMGT_CURRENT_VERSION=${MAVEN_DEPMGT_CURRENT_VERSION_PREFIX}-SNAPSHOT
MAVEN_DEPMGT_NEXT_VERSION=${MAVEN_DEPMGT_NEXT_VERSION_PREFIX}-SNAPSHOT

ADDONS_MANAGER_CURRENT_VERSION_PREFIX=2.0.x
ADDONS_MANAGER_NEXT_VERSION_PREFIX=2.1.x
ADDONS_MANAGER_CURRENT_VERSION=${ADDONS_MANAGER_CURRENT_VERSION_PREFIX}-SNAPSHOT
ADDONS_MANAGER_NEXT_VERSION=${ADDONS_MANAGER_NEXT_VERSION_PREFIX}-SNAPSHOT

# ANSWERS_CURRENT_VERSION_PREFIX=2.2.x
# ANSWERS_NEXT_VERSION_PREFIX=2.3.x
# ANSWERS_CURRENT_VERSION=${ANSWERS_CURRENT_VERSION_PREFIX}-SNAPSHOT
# ANSWERS_NEXT_VERSION=${ANSWERS_NEXT_VERSION_PREFIX}-SNAPSHOT

CAS_CURRENT_VERSION_PREFIX=3.0.x
CAS_NEXT_VERSION_PREFIX=3.1.x
CAS_CURRENT_VERSION=${CAS_CURRENT_VERSION_PREFIX}-SNAPSHOT
CAS_NEXT_VERSION=${CAS_NEXT_VERSION_PREFIX}-SNAPSHOT

CHAT_APPLICATION_CURRENT_VERSION_PREFIX=3.0.x
CHAT_APPLICATION_NEXT_VERSION_PREFIX=3.1.x
CHAT_APPLICATION_CURRENT_VERSION=${CHAT_APPLICATION_CURRENT_VERSION_PREFIX}-SNAPSHOT
CHAT_APPLICATION_NEXT_VERSION=${CHAT_APPLICATION_NEXT_VERSION_PREFIX}-SNAPSHOT

ES_EMBEDDED_CURRENT_VERSION_PREFIX=3.0.x
ES_EMBEDDED_NEXT_VERSION_PREFIX=3.1.x
ES_EMBEDDED_CURRENT_VERSION=${ES_EMBEDDED_CURRENT_VERSION_PREFIX}-SNAPSHOT
ES_EMBEDDED_NEXT_VERSION=${ES_EMBEDDED_NEXT_VERSION_PREFIX}-SNAPSHOT

GAMIFICATION_CURRENT_VERSION_PREFIX=2.0.x
GAMIFICATION_NEXT_VERSION_PREFIX=2.1.x
GAMIFICATION_CURRENT_VERSION=${GAMIFICATION_CURRENT_VERSION_PREFIX}-SNAPSHOT
GAMIFICATION_NEXT_VERSION=${GAMIFICATION_NEXT_VERSION_PREFIX}-SNAPSHOT

KUDOS_CURRENT_VERSION_PREFIX=2.0.x
KUDOS_NEXT_VERSION_PREFIX=2.1.x
KUDOS_CURRENT_VERSION=${KUDOS_CURRENT_VERSION_PREFIX}-SNAPSHOT
KUDOS_NEXT_VERSION=${KUDOS_NEXT_VERSION_PREFIX}-SNAPSHOT

LECKO_CURRENT_VERSION_PREFIX=2.0.x
LECKO_NEXT_VERSION_PREFIX=2.1.x
LECKO_CURRENT_VERSION=${LECKO_CURRENT_VERSION_PREFIX}-SNAPSHOT
LECKO_NEXT_VERSION=${LECKO_NEXT_VERSION_PREFIX}-SNAPSHOT

NEWS_CURRENT_VERSION_PREFIX=2.0.x
NEWS_NEXT_VERSION_PREFIX=2.1.x
NEWS_CURRENT_VERSION=${NEWS_CURRENT_VERSION_PREFIX}-SNAPSHOT
NEWS_NEXT_VERSION=${NEWS_NEXT_VERSION_PREFIX}-SNAPSHOT

OPENAM_CURRENT_VERSION_PREFIX=3.0.x
OPENAM_NEXT_VERSION_PREFIX=3.1.x
OPENAM_CURRENT_VERSION=${OPENAM_CURRENT_VERSION_PREFIX}-SNAPSHOT
OPENAM_NEXT_VERSION=${OPENAM_NEXT_VERSION_PREFIX}-SNAPSHOT

PERKSTORE_CURRENT_VERSION_PREFIX=2.0.x
PERKSTORE_NEXT_VERSION_PREFIX=2.1.x
PERKSTORE_CURRENT_VERSION=${PERKSTORE_CURRENT_VERSION_PREFIX}-SNAPSHOT
PERKSTORE_NEXT_VERSION=${PERKSTORE_NEXT_VERSION_PREFIX}-SNAPSHOT

REMOTE_EDIT_CURRENT_VERSION_PREFIX=3.0.x
REMOTE_EDIT_NEXT_VERSION_PREFIX=3.1.x
REMOTE_EDIT_CURRENT_VERSION=${REMOTE_EDIT_CURRENT_VERSION_PREFIX}-SNAPSHOT
REMOTE_EDIT_NEXT_VERSION=${REMOTE_EDIT_NEXT_VERSION_PREFIX}-SNAPSHOT

SAML2_CURRENT_VERSION_PREFIX=3.0.x
SAML2_NEXT_VERSION_PREFIX=3.1.x
SAML2_CURRENT_VERSION=${SAML2_CURRENT_VERSION_PREFIX}-SNAPSHOT
SAML2_NEXT_VERSION=${SAML2_NEXT_VERSION_PREFIX}-SNAPSHOT

SPNEGO_CURRENT_VERSION_PREFIX=3.0.x
SPNEGO_NEXT_VERSION_PREFIX=3.1.x
SPNEGO_CURRENT_VERSION=${SPNEGO_CURRENT_VERSION_PREFIX}-SNAPSHOT
SPNEGO_NEXT_VERSION=${SPNEGO_NEXT_VERSION_PREFIX}-SNAPSHOT

TASK_CURRENT_VERSION_PREFIX=3.0.x
TASK_NEXT_VERSION_PREFIX=3.1.x
TASK_CURRENT_VERSION=${TASK_CURRENT_VERSION_PREFIX}-SNAPSHOT
TASK_NEXT_VERSION=${TASK_NEXT_VERSION_PREFIX}-SNAPSHOT

WALLET_CURRENT_VERSION_PREFIX=2.0.x
WALLET_NEXT_VERSION_PREFIX=2.1.x
WALLET_CURRENT_VERSION=${WALLET_CURRENT_VERSION_PREFIX}-SNAPSHOT
WALLET_NEXT_VERSION=${WALLET_NEXT_VERSION_PREFIX}-SNAPSHOT

WCM_TEMPLATE_CURRENT_VERSION_PREFIX=3.0.x
WCM_TEMPLATE_NEXT_VERSION_PREFIX=3.1.x
WCM_TEMPLATE_CURRENT_VERSION=${WCM_TEMPLATE_CURRENT_VERSION_PREFIX}-SNAPSHOT
WCM_TEMPLATE_NEXT_VERSION=${WCM_TEMPLATE_NEXT_VERSION_PREFIX}-SNAPSHOT

WEB_CONF_CURRENT_VERSION_PREFIX=2.0.x
WEB_CONF_NEXT_VERSION_PREFIX=2.1.x
WEB_CONF_CURRENT_VERSION=${WEB_CONF_CURRENT_VERSION_PREFIX}-SNAPSHOT
WEB_CONF_NEXT_VERSION=${WEB_CONF_NEXT_VERSION_PREFIX}-SNAPSHOT

PUSH_NOTIFICATIONS_CURRENT_VERSION_PREFIX=2.0.x
PUSH_NOTIFICATIONS_NEXT_VERSION_PREFIX=2.1.x
PUSH_NOTIFICATIONS_CURRENT_VERSION=${PUSH_NOTIFICATIONS_CURRENT_VERSION_PREFIX}-SNAPSHOT
PUSH_NOTIFICATIONS_NEXT_VERSION=${PUSH_NOTIFICATIONS_NEXT_VERSION_PREFIX}-SNAPSHOT

MEEDS_CURRENT_VERSION_PREFIX=1.0.x
MEEDS_NEXT_VERSION_PREFIX=1.1.x
MEEDS_CURRENT_VERSION=${MEEDS_CURRENT_VERSION_PREFIX}-SNAPSHOT
MEEDS_NEXT_VERSION=${MEEDS_NEXT_VERSION_PREFIX}-SNAPSHOT

LEGACY_INTRANET_CURRENT_VERSION_PREFIX=6.0.x
LEGACY_INTRANET_NEXT_VERSION_PREFIX=6.1.x
LEGACY_INTRANET_CURRENT_VERSION=${LEGACY_INTRANET_CURRENT_VERSION_PREFIX}-SNAPSHOT
LEGACY_INTRANET_NEXT_VERSION=${LEGACY_INTRANET_NEXT_VERSION_PREFIX}-SNAPSHOT

APP_CENTER_CURRENT_VERSION_PREFIX=6.0.x
APP_CENTER_NEXT_VERSION_PREFIX=6.1.x
APP_CENTER_CURRENT_VERSION=${APP_CENTER_CURRENT_VERSION_PREFIX}-SNAPSHOT
APP_CENTER_NEXT_VERSION=${APP_CENTER_NEXT_VERSION_PREFIX}-SNAPSHOT

ORIGIN_BRANCH=develop

SCRIPTDIR=$(
	cd $(dirname "$0")
	pwd
)
CURRENTDIR=$(pwd)

PUSH=false
while getopts "p" opt; do
	case $opt in
	p)
		PUSH=true
		;;
	esac
done

function replaceInPom() {
	local descriptor=$1
	local currentVersion=$2
	local nextVersion=$3

	${SCRIPTDIR}/../replaceInPom.sh "<${descriptor}>${currentVersion}</${descriptor}>" "<${descriptor}>${nextVersion}</${descriptor}>"
}

function createSBFromDevelop() {
	local repository=$1
	local devOrga=$2
	local masterBranch=${3:-$ORIGIN_BRANCH}
	local devRemoteName="origin"
	echo "########################################"
	echo "# Repository: $repository"
	echo "########################################"
	pushd $repository
	if [ "$devOrga" != "exoplatform" -a "$devOrga" != "juzu" ]; then
		devRemoteName="${devOrga}"
		devRepoUrl="git@github.com:${devOrga}/${repository}"
		echo "Testing dev repository declaration (${devRepoUrl})..."
		if [ $(git remote -vv | grep -c ${devRepoUrl}) -eq 0 ]; then
			echo "Installing dev repository..."
			git remote add ${devRemoteName} ${devRepoUrl}
			git fetch ${devRemoteName}
		fi
		git reset --hard ${devRemoteName}/${masterBranch}
	fi

	git remote update --prune
	git reset --hard HEAD
	git checkout ${masterBranch}
	git reset --hard origin/${masterBranch}
	git pull

	# add remote on the dev repository if needed

	#update project version on develop branch

	local stableBranch=""
	local nextVersion=""

	case $repository in
	juzu)
		stableBranch=stable/${JUZU_CURRENT_VERSION_PREFIX}
		currentVersion=${JUZU_CURRENT_DEVELOP_VERSION}
		nextVersion=${JUZU_NEXT_DEVELOP_VERSION}
		;;
	gatein-dep)
		stableBranch=stable/${GATEIN_DEP_CURRENT_VERSION_PREFIX}
		currentVersion=${GATEIN_DEP_CURRENT_DEVELOP_VERSION}
		nextVersion=${GATEIN_DEP_NEXT_DEVELOP_VERSION}
		;;
	maven-depmgt-pom)
		stableBranch=stable/${MAVEN_DEPMGT_CURRENT_VERSION_PREFIX}
		currentVersion=${MAVEN_DEPMGT_CURRENT_VERSION}
		nextVersion=${MAVEN_DEPMGT_NEXT_VERSION}
		;;
	addons-manager)
		stableBranch=stable/${ADDONS_MANAGER_CURRENT_VERSION_PREFIX}
		currentVersion=${ADDONS_MANAGER_CURRENT_VERSION}
		nextVersion=${ADDONS_MANAGER_NEXT_VERSION}
		;;
	app-center)
		# Not commented to raise an error if the project is asked
		stableBranch=stable/${APP_CENTER_CURRENT_VERSION_PREFIX}
		currentVersion=${APP_CENTER_CURRENT_VERSION}
		nextVersion=${APP_CENTER_NEXT_VERSION}
		;;	
	answers)
		# Not commented to raise an error if the project is asked
		stableBranch=stable/${ANSWERS_CURRENT_VERSION_PREFIX}
		currentVersion=${ANSWERS_CURRENT_VERSION}
		nextVersion=${ANSWERS_NEXT_VERSION}
		;;
	cas-addon)
		stableBranch=stable/${CAS_CURRENT_VERSION_PREFIX}
		currentVersion=${CAS_CURRENT_VERSION}
		nextVersion=${CAS_NEXT_VERSION}
		;;
	chat-application)
		stableBranch=stable/${CHAT_APPLICATION_CURRENT_VERSION_PREFIX}
		currentVersion=${CHAT_APPLICATION_CURRENT_VERSION}
		nextVersion=${CHAT_APPLICATION_NEXT_VERSION}
		;;
	exo-es-embedded)
		stableBranch=stable/${ES_EMBEDDED_CURRENT_VERSION_PREFIX}
		currentVersion=${ES_EMBEDDED_CURRENT_VERSION}
		nextVersion=${ES_EMBEDDED_NEXT_VERSION}
		;;
	gamification)
		stableBranch=stable/${GAMIFICATION_CURRENT_VERSION_PREFIX}
		currentVersion=${GAMIFICATION_CURRENT_VERSION}
		nextVersion=${GAMIFICATION_NEXT_VERSION}
		;;
	kudos)
		stableBranch=stable/${KUDOS_CURRENT_VERSION_PREFIX}
		currentVersion=${KUDOS_CURRENT_VERSION}
		nextVersion=${KUDOS_NEXT_VERSION}
		;;
	lecko)
		stableBranch=stable/${LECKO_CURRENT_VERSION_PREFIX}
		currentVersion=${LECKO_CURRENT_VERSION}
		nextVersion=${LECKO_NEXT_VERSION}
		;;
	meeds)
		stableBranch=stable/${MEEDS_CURRENT_VERSION_PREFIX}
		currentVersion=${MEEDS_CURRENT_VERSION}
		nextVersion=${MEEDS_NEXT_VERSION}
		;;
	legacy-intranet)
	    stableBranch=stable/${LEGACY_INTRANET_CURRENT_VERSION_PREFIX}
		currentVersion=${LEGACY_INTRANET_CURRENT_VERSION}
		nextVersion=${LEGACY_INTRANET_NEXT_VERSION}
		;;	
	news)
		stableBranch=stable/${NEWS_CURRENT_VERSION_PREFIX}
		currentVersion=${NEWS_CURRENT_VERSION}
		nextVersion=${NEWS_NEXT_VERSION}
		;;
	openam-addon)
		stableBranch=stable/${OPENAM_CURRENT_VERSION_PREFIX}
		currentVersion=${OPENAM_CURRENT_VERSION}
		nextVersion=${OPENAM_NEXT_VERSION}
		;;
	perk-store)
		stableBranch=stable/${PERKSTORE_CURRENT_VERSION_PREFIX}
		currentVersion=${PERKSTORE_CURRENT_VERSION}
		nextVersion=${PERKSTORE_NEXT_VERSION}
		;;
	remote-edit)
		stableBranch=stable/${REMOTE_EDIT_CURRENT_VERSION_PREFIX}
		currentVersion=${REMOTE_EDIT_CURRENT_VERSION}
		nextVersion=${REMOTE_EDIT_NEXT_VERSION}
		;;
	saml2-addon)
		stableBranch=stable/${SAML2_CURRENT_VERSION_PREFIX}
		currentVersion=${SAML2_CURRENT_VERSION}
		nextVersion=${SAML2_NEXT_VERSION}
		;;
	spnego-addon)
		stableBranch=stable/${SPNEGO_CURRENT_VERSION_PREFIX}
		currentVersion=${SPNEGO_CURRENT_VERSION}
		nextVersion=${SPNEGO_NEXT_VERSION}
		;;
	task)
		stableBranch=stable/${TASK_CURRENT_VERSION_PREFIX}
		currentVersion=${TASK_CURRENT_VERSION}
		nextVersion=${TASK_NEXT_VERSION}
		;;
	wallet)
		stableBranch=stable/${WALLET_CURRENT_VERSION_PREFIX}
		currentVersion=${WALLET_CURRENT_VERSION}
		nextVersion=${WALLET_NEXT_VERSION}
		;;
	wcm-template-pack)
		stableBranch=stable/${WCM_TEMPLATE_CURRENT_VERSION_PREFIX}
		currentVersion=${WCM_TEMPLATE_CURRENT_VERSION}
		nextVersion=${WCM_TEMPLATE_NEXT_VERSION}
		;;
	web-conferencing)
		stableBranch=stable/${WEB_CONF_CURRENT_VERSION_PREFIX}
		currentVersion=${WEB_CONF_CURRENT_VERSION}
		nextVersion=${WEB_CONF_NEXT_VERSION}
		;;
	push-notifications)
		stableBranch=stable/${PUSH_NOTIFICATIONS_CURRENT_VERSION_PREFIX}
		currentVersion=${PUSH_NOTIFICATIONS_CURRENT_VERSION}
		nextVersion=${PUSH_NOTIFICATIONS_NEXT_VERSION}
		;;
	*)
		stableBranch=stable/${CURRENT_DEVELOP_VERSION_PREFIX}
		currentVersion=${CURRENT_DEVELOP_VERSION}
		nextVersion=${NEXT_DEVELOP_VERSION}
		;;
	esac
	echo "Create stable branch ${stableBranch}"
	git checkout -f -B ${stableBranch}
	if $PUSH; then
		printf "\e[1;33m# %s\e[m\n" "Create stable branch ${stableBranch} ..."
		git push origin ${stableBranch}
	else
		printf "\e[1;35m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;33m# %s\e[m\n" "Following command would have been executed : |git push origin ${stableBranch}|"
	fi 

	echo "Prepare next version ${nextVersion}"
	git checkout $masterBranch

	replaceInPom version ${currentVersion} ${nextVersion}

	replaceInPom org.juzu.version ${JUZU_CURRENT_DEVELOP_VERSION} ${JUZU_NEXT_DEVELOP_VERSION}

	replaceInPom org.exoplatform.depmgt.version ${MAVEN_DEPMGT_CURRENT_VERSION} ${MAVEN_DEPMGT_NEXT_VERSION}

	replaceInPom org.exoplatform.gatein.wci.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}

	replaceInPom org.exoplatform.kernel.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.core.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.ws.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom addon.exo.jcr.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.gatein.dep.version ${GATEIN_DEP_CURRENT_DEVELOP_VERSION} ${GATEIN_DEP_NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.gatein.sso.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.gatein.pc.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.gatein.portal.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.commons.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.doc.doc-style.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.platform-ui.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom addon.exo.ecms.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.social.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom addon.exo.forum.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom addon.exo.wiki.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom addon.exo.calendar.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.integ.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.platform.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom org.exoplatform.platform.distributions.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}

	replaceInPom org.exoplatform.platform.addons-manager.version ${ADDONS_MANAGER_CURRENT_VERSION} ${ADDONS_MANAGER_NEXT_VERSION}
	replaceInPom addon.exo.es.embedded.version ${ES_EMBEDDED_CURRENT_VERSION} ${ES_EMBEDDED_NEXT_VERSION}
	replaceInPom addon.exo.remote-edit.version ${REMOTE_EDIT_CURRENT_VERSION} ${REMOTE_EDIT_NEXT_VERSION}
	replaceInPom addon.exo.push-notifications.version ${PUSH_NOTIFICATIONS_CURRENT_VERSION} ${PUSH_NOTIFICATIONS_NEXT_VERSION}

	# < 5.0.0
	replaceInPom addon.exo.remote.edit.version ${REMOTE_EDIT_CURRENT_VERSION} ${REMOTE_EDIT_NEXT_VERSION}
	replaceInPom addon.exo.tasks.version ${TASK_CURRENT_VERSION} ${TASK_NEXT_VERSION}
	replaceInPom addon.exo.web-pack.version ${WCM_TEMPLATE_CURRENT_VERSION} ${WCM_TEMPLATE_NEXT_VERSION}

	# >= 5.0.0
	replaceInPom addon.exo.web.pack.version ${WCM_TEMPLATE_CURRENT_VERSION} ${WCM_TEMPLATE_NEXT_VERSION}
	replaceInPom addon.exo.web-conferencing.version ${WEB_CONF_CURRENT_VERSION} ${WEB_CONF_NEXT_VERSION}
	replaceInPom addon.exo.enterprise-skin.version ${CURRENT_DEVELOP_VERSION} ${NEXT_DEVELOP_VERSION}
	replaceInPom addon.exo.chat.version ${CHAT_APPLICATION_CURRENT_VERSION} ${CHAT_APPLICATION_NEXT_VERSION}
	replaceInPom addon.exo.gamification.version ${GAMIFICATION_CURRENT_VERSION} ${GAMIFICATION_NEXT_VERSION}
	replaceInPom addon.exo.news.version ${NEWS_CURRENT_VERSION} ${NEWS_NEXT_VERSION}
	replaceInPom addon.exo.kudos.version ${KUDOS_CURRENT_VERSION} ${KUDOS_NEXT_VERSION}
	replaceInPom addon.exo.perk-store.version ${PERKSTORE_CURRENT_VERSION} ${PERKSTORE_NEXT_VERSION}
	replaceInPom addon.exo.wallet.version ${WALLET_CURRENT_VERSION} ${WALLET_NEXT_VERSION}
	replaceInPom io.meeds.distribution.version ${MEEDS_CURRENT_VERSION} ${MEEDS_NEXT_VERSION}
	replaceInPom addon.exo.layout-management.version ${LEGACY_INTRANET_CURRENT_VERSION} ${LEGACY_INTRANET_NEXT_VERSION}
	replaceInPom addon.exo.app-center.version ${APP_CENTER_CURRENT_VERSION} ${APP_CENTER_NEXT_VERSION}

	git commit -m "$ISSUE: Update project versions to ${nextVersion}" -a

	if $PUSH; then
		printf "\e[1;35m# %s\e[m\n" "Pushing ${masterBranch} ..."	  
		git push ${devRemoteName} ${masterBranch}
	else
		printf "\e[1;35m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;33m# %s\e[m\n" "Following command would have been executed : |git push ${devRemoteName} ${masterBranch}|"
		printf "\e[1;33m# %s\e[m\n" "Launching gitk to display the changes ..."
		gitk --all
	fi 

	popd
}

# Not yet supported
# createSBFromDevelop cf-parent exoplatform
createSBFromDevelop maven-depmgt-pom

# Supported
# Not since 5.1
# createSBFromDevelop juzu juzu master

createSBFromDevelop gatein-wci meeds-io
createSBFromDevelop kernel meeds-io
createSBFromDevelop core meeds-io
createSBFromDevelop ws meeds-io
createSBFromDevelop jcr exodev
createSBFromDevelop gatein-dep meeds-io
createSBFromDevelop gatein-sso meeds-io
createSBFromDevelop gatein-pc meeds-io
createSBFromDevelop gatein-portal meeds-io

## PLF
#createSBFromDevelop docs-style exodev
createSBFromDevelop platform-ui exodev
createSBFromDevelop commons exodev
createSBFromDevelop ecms exodev
createSBFromDevelop social meeds-io
createSBFromDevelop wiki exodev
createSBFromDevelop forum exodev
createSBFromDevelop calendar exodev


## Addons
createSBFromDevelop addons-manager meeds-io
# Not since 5.2
# createSBFromDevelop answers exo-addons
createSBFromDevelop cas-addon exo-addons
createSBFromDevelop chat-application exo-addons
createSBFromDevelop cmis-addon exo-addons
createSBFromDevelop exo-es-embedded meeds-io
#createSBFromDevelop enterprise-skin exoplatform
createSBFromDevelop gamification meeds-io
createSBFromDevelop kudos meeds-io
createSBFromDevelop lecko exo-addons
createSBFromDevelop news exo-addons
createSBFromDevelop openam-addon exo-addons
createSBFromDevelop perk-store meeds-io
createSBFromDevelop remote-edit exo-addons
createSBFromDevelop saml2-addon exo-addons
createSBFromDevelop spnego-addon exo-addons
createSBFromDevelop task exo-addons
createSBFromDevelop wallet meeds-io
createSBFromDevelop wcm-template-pack exo-addons
createSBFromDevelop web-conferencing exo-addons
createSBFromDevelop push-notifications meeds-io
createSBFromDevelop app-center meeds-io

## Distrib
createSBFromDevelop platform-public-distributions exoplatform
createSBFromDevelop meeds meeds-io
# createSBFromDevelop platform-private-trial-distributions exoplatform
