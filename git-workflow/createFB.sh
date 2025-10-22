#!/bin/bash -eu

# Create Git Feature Branches for PLF projects

# Function to display the help message
show_help() {
    printf "\e[1;33m%s\e[m\n" "Usage: $0 [-p] FBRANCH ORIGIN_BRANCH PROJECT_VERSION DEPMGT_VERSION ISSUE"
    echo
    echo "Options:"
    echo "  -p       Execute the script with the 'p' option to activate push"
    echo "  -h       Display this help message"
    echo
    echo "Arguments: "
    echo "  FBRANCH           Name of Feature Branch"
    echo "  ORIGIN_BRANCH     Branch to base the feature branch on (develop-meed or develop-exo or develop (Default)):"
    echo "                      - For Meeds repos: develop-meed or develop-exo or develop (Default)"
    echo "                      - For eXo Platform repos: ignored, develop is always used, regardless of origin_branch"
    echo "  PROJECT_VERSION   Current project version (e.g. 7.2.x)"
    echo "  DEPMGT_VERSION    Dependency management version (e.g. 25.x)"
    echo "  ISSUE             Task or ticket ID"
    echo
}

PUSH=false
while getopts "ph" opt; do
    case $opt in
        p)
            PUSH=true
            ;;
        h)
            show_help
            exit 0
            ;;
        \?)
            printf "\e[1;31m%s\e[m\n" "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
    esac
done

# Shift processed options
shift $((OPTIND-1))

# Check arguments count
if [ $# -ne 5 ]; then
    printf "\e[1;31m%s\e[m\n" "Error: Exactly five arguments are required."
    show_help
    exit 1
fi

# Assign positional arguments
FBRANCH=$1
ORIGIN_BRANCH=$2   # develop-meed or develop-exo or develop
PROJECT_VERSION=$3
DEPMGT_VERSION=$4
ISSUE=$5

# Define defaults
DEFAULT_BRANCH="develop"
TARGET_BRANCH="feature/$FBRANCH"
TARGET_VERSION="${PROJECT_VERSION}-${FBRANCH}-SNAPSHOT"
DEPMGT_TARGET_VERSION="${DEPMGT_VERSION}-${FBRANCH}-SNAPSHOT"
MEEDS_DISTRIB=""  # '-exo', '-meed', or ''


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

	if [ ! -d "${repo_name}" ]; then
    		git clone git@github.com:${organization}/${repo_name}.git ${repo_name}
	else
    		echo "Repo ${repo_name} already exists, skipping clone"
        fi
	# git checkout ${ORIGIN_BRANCH} && git branch | grep -v "${ORIGIN_BRANCH}" | xargs git branch -d -D
	printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
	# git checkout $ORIGIN_BRANCH
	# git branch -D $TARGET_BRANCH
	pushd ${repo_name}
	git remote update --prune
	git reset --hard HEAD
	[ -n "${ORIGIN_BRANCH:-}" ] && git checkout "$ORIGIN_BRANCH" || git checkout "$DEFAULT_BRANCH"
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
	local organization=$2
	printf "\e[1;33m# %s\e[m\n" "Modifying versions in the project POMs ($repo_name) ..."
	set -e
	case $organization in	
	Meeds-io) 
	 	case $repo_name in
            maven-depmgt-pom) $SCRIPTDIR/../replaceInFile.sh "<version>$DEPMGT_ORIGIN_VERSION</version>" "<version>$DEPMGT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
            *) $SCRIPTDIR/../replaceInFile.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
        esac ;;
	exoplatform)
		case $repo_name in
            maven-exo-depmgt-pom) $SCRIPTDIR/../replaceInFile.sh "<version>$DEPMGT_ORIGIN_VERSION</version>" "<version>$DEPMGT_TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
            *) $SCRIPTDIR/../replaceInFile.sh "<version>$ORIGIN_VERSION</version>" "<version>$TARGET_VERSION</version>" "pom.xml -not -wholename \"*/target/*\"" ;;
        esac ;;
	esac
}

function replaceProjectDeps() {
	printf "\e[1;33m# %s\e[m\n" "Modifying dependencies versions in the project POMs ($repo_name) ..."

	#Meeds
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.gatein.wci.version>$ORIGIN_VERSION</io.meeds.gatein.wci.version>" "<io.meeds.gatein.wci.version>$TARGET_VERSION</io.meeds.gatein.wci.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.kernel.version>$ORIGIN_VERSION</io.meeds.kernel.version>" "<io.meeds.kernel.version>$TARGET_VERSION</io.meeds.kernel.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.core.version>$ORIGIN_VERSION</io.meeds.core.version>" "<io.meeds.core.version>$TARGET_VERSION</io.meeds.core.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.ws.version>$ORIGIN_VERSION</io.meeds.ws.version>" "<io.meeds.ws.version>$TARGET_VERSION</io.meeds.ws.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.gatein.sso.version>$ORIGIN_VERSION</io.meeds.gatein.sso.version>" "<io.meeds.gatein.sso.version>$TARGET_VERSION</io.meeds.gatein.sso.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.gatein.pc.version>$ORIGIN_VERSION</io.meeds.gatein.pc.version>" "<io.meeds.gatein.pc.version>$TARGET_VERSION</io.meeds.gatein.pc.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.portal.version>$ORIGIN_VERSION</io.meeds.portal.version>" "<io.meeds.portal.version>$TARGET_VERSION</io.meeds.portal.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.depmgt.version>$DEPMGT_ORIGIN_VERSION</io.meeds.depmgt.version>" "<io.meeds.depmgt.version>$DEPMGT_TARGET_VERSION</io.meeds.depmgt.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.platform-ui.version>$ORIGIN_VERSION</io.meeds.platform-ui.version>" "<io.meeds.platform-ui.version>$TARGET_VERSION</io.meeds.platform-ui.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.commons.version>$ORIGIN_VERSION</io.meeds.commons.version>" "<io.meeds.commons.version>$TARGET_VERSION</io.meeds.commons.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.social.version>$ORIGIN_VERSION</io.meeds.social.version>" "<io.meeds.social.version>$TARGET_VERSION</io.meeds.social.version>" "pom.xml -not -wholename \"*/target/*\""	
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.platform.addons-manager.version>$ORIGIN_VERSION</io.meeds.platform.addons-manager.version>" "<io.meeds.platform.addons-manager.version>$TARGET_VERSION</io.meeds.platform.addons-manager.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.distribution.version>$ORIGIN_VERSION</io.meeds.distribution.version>" "<io.meeds.distribution.version>$TARGET_VERSION</io.meeds.distribution.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<io.meeds.billing.version>$ORIGIN_VERSION</io.meeds.billing.version>" "<io.meeds.billing.version>$TARGET_VERSION</io.meeds.billing.version>" "pom.xml -not -wholename \"*/target/*\""

	#eXoplatform
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.maven-exo-depmgt-pom.version>$DEPMGT_ORIGIN_VERSION</org.exoplatform.maven-exo-depmgt-pom.version>" "<org.exoplatform.maven-exo-depmgt-pom.version>$DEPMGT_TARGET_VERSION</org.exoplatform.maven-exo-depmgt-pom.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<org.exoplatform.commons-exo.version>$ORIGIN_VERSION</org.exoplatform.commons-exo.version>" "<org.exoplatform.commons-exo.version>$TARGET_VERSION</org.exoplatform.commons-exo.version>" "pom.xml -not -wholename \"*/target/*\""
}

function replaceProjectAddons() {
	printf "\e[1;33m# %s\e[m\n" "Modifying add-ons versions in the packaging project POMs ($repo_name) ..."
	
	#Meeds
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.layout.version>$ORIGIN_VERSION</addon.meeds.layout.version>" "<addon.meeds.layout.version>$TARGET_VERSION</addon.meeds.layout.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.gamification.version>$ORIGIN_VERSION</addon.meeds.gamification.version>" "<addon.meeds.gamification.version>$TARGET_VERSION</addon.meeds.gamification.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.kudos.version>$ORIGIN_VERSION</addon.meeds.kudos.version>" "<addon.meeds.kudos.version>$TARGET_VERSION</addon.meeds.kudos.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.perk-store.version>$ORIGIN_VERSION</addon.meeds.perk-store.version>" "<addon.meeds.perk-store.version>$TARGET_VERSION</addon.meeds.perk-store.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.wallet.version>$ORIGIN_VERSION</addon.meeds.wallet.version>" "<addon.meeds.wallet.version>$TARGET_VERSION</addon.meeds.wallet.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.app-center.version>$ORIGIN_VERSION</addon.meeds.app-center.version>" "<addon.meeds.app-center.version>$TARGET_VERSION</addon.meeds.app-center.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.push-notifications.version>$ORIGIN_VERSION</addon.meeds.push-notifications.version>" "<addon.meeds.push-notifications.version>$TARGET_VERSION</addon.meeds.push-notifications.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.analytics.version>$ORIGIN_VERSION</addon.meeds.analytics.version>" "<addon.meeds.analytics.version>$TARGET_VERSION</addon.meeds.analytics.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.notes.version>$ORIGIN_VERSION</addon.meeds.notes.version>" "<addon.meeds.notes.version>$TARGET_VERSION</addon.meeds.notes.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.content.version>$ORIGIN_VERSION</addon.meeds.content.version>" "<addon.meeds.content.version>$TARGET_VERSION</addon.meeds.content.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.poll.version>$ORIGIN_VERSION</addon.meeds.poll.version>" "<addon.meeds.poll.version>$TARGET_VERSION</addon.meeds.poll.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.tasks.version>$ORIGIN_VERSION</addon.meeds.tasks.version>" "<addon.meeds.tasks.version>$TARGET_VERSION</addon.meeds.tasks.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.gamification-github.version>$ORIGIN_VERSION</addon.meeds.gamification-github.version>" "<addon.meeds.gamification-github.version>$TARGET_VERSION</addon.meeds.gamification-github.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.gamification-twitter.version>$ORIGIN_VERSION</addon.meeds.gamification-twitter.version>" "<addon.meeds.gamification-twitter.version>$TARGET_VERSION</addon.meeds.gamification-twitter.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.gamification-evm.version>$ORIGIN_VERSION</addon.meeds.gamification-evm.version>" "<addon.meeds.gamification-evm.version>$TARGET_VERSION</addon.meeds.gamification-evm.version>" "pom.xml -not -wholename \"*/target/*\""
    $SCRIPTDIR/../replaceInFile.sh "<addon.meeds.gamification-crowdin.version>$ORIGIN_VERSION</addon.meeds.gamification-crowdin.version>" "<addon.meeds.gamification-crowdin.version>$TARGET_VERSION</addon.meeds.gamification-crowdin.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.pwa.version>$ORIGIN_VERSION</addon.meeds.pwa.version>" "<addon.meeds.pwa.version>$TARGET_VERSION</addon.meeds.pwa.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.ide.version>$ORIGIN_VERSION</addon.meeds.ide.version>" "<addon.meeds.ide.version>$TARGET_VERSION</addon.meeds.ide.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.matrix.version>$ORIGIN_VERSION</addon.meeds.matrix.version>" "<addon.meeds.matrix.version>$TARGET_VERSION</addon.meeds.matrix.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.deeds-tenant.version>$ORIGIN_VERSION</addon.meeds.deeds-tenant.version>" "<addon.meeds.deeds-tenant.version>$TARGET_VERSION</addon.meeds.deeds-tenant.version>" "pom.xml -not -wholename \"*/target/*\""

	#eXoplatform
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.jcr.version>$ORIGIN_VERSION</addon.exo.jcr.version>" "<addon.exo.jcr.version>$TARGET_VERSION</addon.exo.jcr.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.ecms.version>$ORIGIN_VERSION</addon.exo.ecms.version>" "<addon.exo.ecms.version>$TARGET_VERSION</addon.exo.ecms.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.web-conferencing.version>$ORIGIN_VERSION</addon.exo.web-conferencing.version>" "<addon.exo.web-conferencing.version>$TARGET_VERSION</addon.exo.web-conferencing.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.jitsi.version>$ORIGIN_VERSION</addon.exo.jitsi.version>" "<addon.exo.jitsi.version>$TARGET_VERSION</addon.exo.jitsi.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.agenda.version>$ORIGIN_VERSION</addon.exo.agenda.version>" "<addon.exo.agenda.version>$TARGET_VERSION</addon.exo.agenda.version>" "pom.xml -not -wholename \"*/target/*\""	
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.agenda-connectors.version>$ORIGIN_VERSION</addon.exo.agenda-connectors.version>" "<addon.exo.agenda-connectors.version>$TARGET_VERSION</addon.exo.agenda-connectors.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.digital-workplace.version>$ORIGIN_VERSION</addon.exo.digital-workplace.version>" "<addon.exo.digital-workplace.version>$TARGET_VERSION</addon.exo.digital-workplace.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.data-upgrade.version>$ORIGIN_VERSION</addon.exo.data-upgrade.version>" "<addon.exo.data-upgrade.version>$TARGET_VERSION</addon.exo.data-upgrade.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.onlyoffice.version>$ORIGIN_VERSION</addon.exo.onlyoffice.version>" "<addon.exo.onlyoffice.version>$TARGET_VERSION</addon.exo.onlyoffice.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.chat.version>$ORIGIN_VERSION</addon.exo.chat.version>" "<addon.exo.chat.version>$TARGET_VERSION</addon.exo.chat.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.multifactor-authentication.version>$ORIGIN_VERSION</addon.exo.multifactor-authentication.version>" "<addon.exo.multifactor-authentication.version>$TARGET_VERSION</addon.exo.multifactor-authentication.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.automatic-translation.version>$ORIGIN_VERSION</addon.exo.automatic-translation.version>" "<addon.exo.automatic-translation.version>$TARGET_VERSION</addon.exo.automatic-translation.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.documents.version>$ORIGIN_VERSION</addon.exo.documents.version>" "<addon.exo.documents.version>$TARGET_VERSION</addon.exo.documents.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.processes.version>$ORIGIN_VERSION</addon.exo.processes.version>" "<addon.exo.processes.version>$TARGET_VERSION</addon.exo.processes.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.anti-bruteforce.version>$ORIGIN_VERSION</addon.exo.anti-bruteforce.version>" "<addon.exo.anti-bruteforce.version>$TARGET_VERSION</addon.exo.anti-bruteforce.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.anti-malware.version>$ORIGIN_VERSION</addon.exo.anti-malware.version>" "<addon.exo.anti-malware.version>$TARGET_VERSION</addon.exo.anti-malware.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.dlp.version>$ORIGIN_VERSION</addon.exo.dlp.version>" "<addon.exo.dlp.version>$TARGET_VERSION</addon.exo.dlp.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.cloud-drive-connectors.version>$ORIGIN_VERSION</addon.exo.cloud-drive-connectors.version>" "<addon.exo.cloud-drive-connectors.version>$TARGET_VERSION</addon.exo.cloud-drive-connectors.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.external-visio-connector.version>$ORIGIN_VERSION</addon.exo.external-visio-connector.version>" "<addon.exo.external-visio-connector.version>$TARGET_VERSION</addon.exo.external-visio-connector.version>" "pom.xml -not -wholename \"*/target/*\""

}

function createFB() {
	local repo_name=$1
	local organization=$2

	printf "\e[1;32m# %s\e[m\n" "====================================================================="
	printf "\e[1;32m# %s\e[m\n" "Create the Feature Branch $TARGET_BRANCH for ($repo_name) ..."
	printf "\e[1;32m# %s\e[m\n" "====================================================================="
	
	repoCleanup ${repo_name} ${organization}
	 
    if [[ "$ORIGIN_BRANCH" == "develop-exo" && "$organization" == "Meeds-io" ]]; then
        MEEDS_DISTRIB="-exo"
        ORIGIN_VERSION="${PROJECT_VERSION}${MEEDS_DISTRIB}-SNAPSHOT"
        # Meeds - Maven DEPMGT
        DEPMGT_ORIGIN_VERSION="${DEPMGT_VERSION}${MEEDS_DISTRIB}-SNAPSHOT"  
    elif [[ "$ORIGIN_BRANCH" == "develop-meed" && "$organization" == "Meeds-io" ]]; then
        MEEDS_DISTRIB="-meed"
        ORIGIN_VERSION="${PROJECT_VERSION}${MEEDS_DISTRIB}-SNAPSHOT"
        # eXo Platform - Maven DEPMGT
        DEPMGT_ORIGIN_VERSION="${DEPMGT_VERSION}${MEEDS_DISTRIB}-SNAPSHOT"    
    else
		ORIGIN_BRANCH="$DEFAULT_BRANCH"
        ORIGIN_VERSION="${PROJECT_VERSION}-SNAPSHOT"
        # eXo Platform - Maven DEPMGT
        DEPMGT_ORIGIN_VERSION="${DEPMGT_VERSION}-SNAPSHOT"
    fi
    
    replaceProjectVersion ${repo_name} ${organization}
	replaceProjectDeps ${repo_name}
	replaceProjectAddons ${repo_name}

	# Replace add-on versions in distributions project
	# case $repo_name in
	# *-distributions) replaceProjectAddons ${repo_name} ;;
	# esac

	printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ($repo_name) ..."
	git add -u && git commit -m "$ISSUE: Create FB $FBRANCH and update projects versions/dependencies" 
	# git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream

	if [ "$PUSH" = true ]; then
		printf "\e[1;33m# %s\e[m\n" "Pushing commit to ${TARGET_BRANCH} ..."
		git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream
		# Return on dev branch only in real runs to easily debug during test phase
		[ ! -z "{ORIGIN_BRANCH:-}" ] && git checkout $ORIGIN_BRANCH || git checkout $DEFAULT_BRANCH
	else
		printf "\e[1;31m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;31m# %s\e[m\n" "Following command would have been executed : | git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream|"
	fi
	popd
}

pushd ${SWF_FB_REPOS}
echo "==================================="
echo "SWF_FB_REPOS : ${SWF_FB_REPOS}"
echo "==================================="

#Meeds Projects
 createFB maven-depmgt-pom Meeds-io
 createFB gatein-wci Meeds-io
 createFB kernel Meeds-io
 createFB core Meeds-io
 createFB ws Meeds-io
 createFB portlet-container Meeds-io
 createFB gatein-sso Meeds-io
 createFB portal Meeds-io
 createFB platform-ui Meeds-io
 createFB commons Meeds-io
 createFB social Meeds-io
 createFB layout Meeds-io
 createFB gamification Meeds-io
 createFB kudos Meeds-io
 createFB perk-store Meeds-io
 createFB wallet Meeds-io
 createFB push-notifications Meeds-io
 createFB app-center Meeds-io
 createFB analytics Meeds-io
 createFB notes Meeds-io
 createFB content Meeds-io
 createFB poll Meeds-io
 createFB task Meeds-io
 createFB gamification-github Meeds-io
 createFB gamification-twitter Meeds-io
 createFB gamification-evm Meeds-io
 createFB gamification-crowdin Meeds-io
 createFB pwa Meeds-io
 createFB ide Meeds-io
 createFB matrix Meeds-io
 createFB addons-manager Meeds-io
 createFB deeds-tenant Meeds-io
 createFB meeds Meeds-io
 createFB billing Meeds-io

 # # Explatform projects
 createFB maven-exo-depmgt-pom exoplatform
 createFB commons-exo exoplatform
 createFB jcr exoplatform
 createFB ecms exoplatform
 createFB mail-integration exoplatform
 createFB email-connector exoplatform
 createFB cloud-drive-connectors exoplatform
 createFB dlp exoplatform
 createFB agenda exoplatform
 createFB agenda-connectors exoplatform
 createFB chat-application exoplatform
 createFB digital-workplace exoplatform
 createFB onlyoffice exoplatform
 createFB saml2-addon exoplatform
 createFB web-conferencing exoplatform
 createFB jitsi-call exoplatform
 createFB jitsi exoplatform
 createFB multifactor-authentication exoplatform
 createFB automatic-translation exoplatform
 createFB documents exoplatform
 createFB processes exoplatform
 createFB data-upgrade exoplatform
 createFB anti-bruteforce exoplatform
 createFB anti-malware exoplatform
 createFB external-visio-connector exoplatform
 createFB platform-private-distributions exoplatform
popd

echo
printf "\e[1;33m# %s\e[m\n" "Feature branch ${FBRANCH} created"
