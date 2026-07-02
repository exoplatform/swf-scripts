#!/bin/bash -eu

# Create Git Feature Branches for PLF projects

# Function to display the help message
show_help() {
    printf "\e[1;33m%s\e[m\n" "Usage: $0 [-p] FBRANCH PROJECT_VERSION DEPMGT_VERSION ISSUE"
    echo
    echo "Options:"
    echo "  -p       Execute the script with the 'p' option to activate push"
    echo "  -h       Display this help message"
    echo
    echo "Arguments: "
    echo "  FBRANCH           Name of Feature Branch"
    echo "  PROJECT_VERSION   Current project version (e.g. 7.3.x)"
    echo "  DEPMGT_VERSION    Dependency management version (e.g. 26.x)"
    echo "  ISSUE             Task or ticket ID"
    echo
    echo "Notes:"
    echo "  - All Feature Branches are systematically created from 'develop'."
    echo "  - The script asks, once, whether existing Feature Branches should be"
    echo "    deleted and recreated from develop, or kept with their existing commits."
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
if [ $# -ne 4 ]; then
    printf "\e[1;31m%s\e[m\n" "Error: Exactly four arguments are required."
    show_help
    exit 1
fi

# Assign positional arguments
FBRANCH=$1
PROJECT_VERSION=$2
DEPMGT_VERSION=$3
ISSUE=$4

# Define defaults
DEFAULT_BRANCH="develop"
TARGET_BRANCH="feature/$FBRANCH"
TARGET_VERSION="${PROJECT_VERSION}-${FBRANCH}-SNAPSHOT"
DEPMGT_TARGET_VERSION="${DEPMGT_VERSION}-${FBRANCH}-SNAPSHOT"

# Les versions d'origine ne dependent plus de develop-meed / develop-exo :
# tout part desormais de develop.
ORIGIN_VERSION="${PROJECT_VERSION}-SNAPSHOT"
DEPMGT_ORIGIN_VERSION="${DEPMGT_VERSION}-SNAPSHOT"

SCRIPTDIR=$(
	cd $(dirname "$0")
	pwd
)
CURRENTDIR=$(pwd)

SWF_FB_REPOS=${SWF_FB_REPOS:-$CURRENTDIR}
echo "==================================="
echo "SWF_FB_REPOS : ${SWF_FB_REPOS}"
echo "==================================="

# --- Demande interactive (posee une seule fois pour tous les projets) ---
FB_STRATEGY=""
while [[ "$FB_STRATEGY" != "1" && "$FB_STRATEGY" != "2" ]]; do
	echo
	printf "\e[1;36m%s\e[m\n" "What should be done if Feature Branch '${TARGET_BRANCH}' already exists in a repo?"
	echo "  1) Delete the existing branch and recreate it from develop"
	echo "  2) Keep the existing branch and its commits"
	read -p "Your choice [1/2]: " FB_STRATEGY
done

if [ "$FB_STRATEGY" == "1" ]; then
	printf "\e[1;33m# %s\e[m\n" "Chosen strategy: delete + recreate from develop"
else
	printf "\e[1;33m# %s\e[m\n" "Chosen strategy: keep existing branches and commits"
fi

function repoCleanup() {
	local repo_name=$1
	local organization=$2

	if [ ! -d "${repo_name}" ]; then
    		git clone git@github.com:${organization}/${repo_name}.git ${repo_name}
	else
    		echo "Repo ${repo_name} already exists, skipping clone"
        fi
	printf "\e[1;33m# %s\e[m\n" "Cleaning of ${repo_name} repository ..."
	pushd ${repo_name}
	git remote update --prune
	git reset --hard HEAD
	git checkout "$DEFAULT_BRANCH"
	git reset --hard HEAD
	git pull

	printf "\e[1;33m# %s\e[m\n" "Testing if ${TARGET_BRANCH} branch already exists ($repo_name) ..."
	GIT_PUSH_PARAMS=""

	set +e
	git rev-parse --verify --quiet "$TARGET_BRANCH" >/dev/null
	BRANCH_EXISTS=$?
	set -e

	if [ "$BRANCH_EXISTS" -ne 0 ]; then
		printf "\e[1;33m# %s\e[m\n" "Branch ${TARGET_BRANCH} does not exist yet, creating it ($repo_name) ..."
		git checkout -b $TARGET_BRANCH
	elif [ "$FB_STRATEGY" == "1" ]; then
		printf "\e[1;35m# %s\e[m\n" "Branch ${TARGET_BRANCH} already exists: deleting then recreating it from ${DEFAULT_BRANCH} ($repo_name) ..."
		git checkout $DEFAULT_BRANCH
		git branch -D $TARGET_BRANCH
		git checkout -b $TARGET_BRANCH
		GIT_PUSH_PARAMS="--force"
	else
		printf "\e[1;35m# %s\e[m\n" "Branch ${TARGET_BRANCH} already exists: keeping the branch and its commits ($repo_name) ..."
		git checkout $TARGET_BRANCH
		printf "\e[1;33m# %s\e[m\n" "Merging ${DEFAULT_BRANCH} into ${TARGET_BRANCH} to pick up the new version ($repo_name) ..."
		set +e
		git merge --no-edit $DEFAULT_BRANCH
		MERGE_STATUS=$?
		set -e
		if [ "$MERGE_STATUS" -ne 0 ]; then
			printf "\e[1;31m# %s\e[m\n" "Merge conflict while merging ${DEFAULT_BRANCH} into ${TARGET_BRANCH} ($repo_name). Please resolve manually."
			exit 1
		fi
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
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.auth-server.version>$ORIGIN_VERSION</addon.meeds.auth-server.version>" "<addon.meeds.auth-server.version>$TARGET_VERSION</addon.meeds.auth-server.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.mcp-server.version>$ORIGIN_VERSION</addon.meeds.mcp-server.version>" "<addon.meeds.mcp-server.version>$TARGET_VERSION</addon.meeds.mcp-server.version>" "pom.xml -not -wholename \"*/target/*\""
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
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.ai.version>$ORIGIN_VERSION</addon.meeds.ai.version>" "<addon.meeds.ai.version>$TARGET_VERSION</addon.meeds.ai.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.meeds.billing.version>$ORIGIN_VERSION</addon.meeds.billing.version>" "<addon.meeds.billing.version>$TARGET_VERSION</addon.meeds.billing.version>" "pom.xml -not -wholename \"*/target/*\""

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
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.multifactor-authentication.version>$ORIGIN_VERSION</addon.exo.multifactor-authentication.version>" "<addon.exo.multifactor-authentication.version>$TARGET_VERSION</addon.exo.multifactor-authentication.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.automatic-translation.version>$ORIGIN_VERSION</addon.exo.automatic-translation.version>" "<addon.exo.automatic-translation.version>$TARGET_VERSION</addon.exo.automatic-translation.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.documents.version>$ORIGIN_VERSION</addon.exo.documents.version>" "<addon.exo.documents.version>$TARGET_VERSION</addon.exo.documents.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.processes.version>$ORIGIN_VERSION</addon.exo.processes.version>" "<addon.exo.processes.version>$TARGET_VERSION</addon.exo.processes.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.anti-bruteforce.version>$ORIGIN_VERSION</addon.exo.anti-bruteforce.version>" "<addon.exo.anti-bruteforce.version>$TARGET_VERSION</addon.exo.anti-bruteforce.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.anti-malware.version>$ORIGIN_VERSION</addon.exo.anti-malware.version>" "<addon.exo.anti-malware.version>$TARGET_VERSION</addon.exo.anti-malware.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.dlp.version>$ORIGIN_VERSION</addon.exo.dlp.version>" "<addon.exo.dlp.version>$TARGET_VERSION</addon.exo.dlp.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.email-connector.version>$ORIGIN_VERSION</addon.exo.email-connector.version>" "<addon.exo.email-connector.version>$TARGET_VERSION</addon.exo.email-connector.version>" "pom.xml -not -wholename \"*/target/*\""
    $SCRIPTDIR/../replaceInFile.sh "<addon.exo.external-visio-connector.version>$ORIGIN_VERSION</addon.exo.external-visio-connector.version>" "<addon.exo.external-visio-connector.version>$TARGET_VERSION</addon.exo.external-visio-connector.version>" "pom.xml -not -wholename \"*/target/*\""
	$SCRIPTDIR/../replaceInFile.sh "<addon.exo.caldav-integration.version>$ORIGIN_VERSION</addon.exo.caldav-integration.version>" "<addon.exo.caldav-integration.version>$TARGET_VERSION</addon.exo.caldav-integration.version>" "pom.xml -not -wholename \"*/target/*\""

}

function createFB() {
	local repo_name=$1
	local organization=$2

	printf "\e[1;32m# %s\e[m\n" "====================================================================="
	printf "\e[1;32m# %s\e[m\n" "Create the Feature Branch $TARGET_BRANCH for ($repo_name) ..."
	printf "\e[1;32m# %s\e[m\n" "====================================================================="

	repoCleanup ${repo_name} ${organization}

	replaceProjectVersion ${repo_name} ${organization}
	replaceProjectDeps ${repo_name}
	replaceProjectAddons ${repo_name}

	printf "\e[1;33m# %s\e[m\n" "Commiting and pushing the new $TARGET_BRANCH branch to origin ($repo_name) ..."
	set +e
	git add -u && git commit -m "$ISSUE: Create FB $FBRANCH and update projects versions/dependencies"
	set -e

	if [ "$PUSH" = true ]; then
		printf "\e[1;33m# %s\e[m\n" "Pushing commit to ${TARGET_BRANCH} ..."
		git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream
	else
		printf "\e[1;31m# %s\e[m\n" "Push is disabled (use -p to activate it) ..."
		printf "\e[1;31m# %s\e[m\n" "Following command would have been executed : | git push $GIT_PUSH_PARAMS origin $TARGET_BRANCH --set-upstream|"
	fi

	# Always return to develop, whether push is enabled or not
	git checkout $DEFAULT_BRANCH
	popd
}

pushd ${SWF_FB_REPOS}
echo "==================================="
echo "SWF_FB_REPOS : ${SWF_FB_REPOS}"
echo "==================================="

#Meeds Projects
#    createFB maven-depmgt-pom Meeds-io
#    createFB gatein-wci Meeds-io
#    createFB kernel Meeds-io
#    createFB core Meeds-io
#    createFB ws Meeds-io
#    createFB portlet-container Meeds-io
#    createFB gatein-sso Meeds-io
#    createFB portal Meeds-io
#    createFB platform-ui Meeds-io
#    createFB commons Meeds-io
#    createFB social Meeds-io
#    createFB layout Meeds-io
#    createFB auth-server Meeds-io
#    createFB gamification Meeds-io
#    createFB kudos Meeds-io
#    createFB perk-store Meeds-io
#    createFB wallet Meeds-io
#    createFB push-notifications Meeds-io
#    createFB app-center Meeds-io
#    createFB mcp-server Meeds-io
#    createFB analytics Meeds-io
#    createFB notes Meeds-io
#    createFB content Meeds-io
#    createFB poll Meeds-io
#    createFB task Meeds-io
#    createFB gamification-github Meeds-io
#    createFB gamification-twitter Meeds-io
#    createFB gamification-evm Meeds-io
#    createFB gamification-crowdin Meeds-io
#    createFB pwa Meeds-io
#    createFB ide Meeds-io
#    createFB matrix Meeds-io
#    createFB ai Meeds-io
#    createFB addons-manager Meeds-io
#    createFB deeds-tenant Meeds-io
#    createFB meeds Meeds-io
#    createFB billing Meeds-io

#  # # Explatform projects
   createFB maven-exo-depmgt-pom exoplatform
   createFB commons-exo exoplatform
   #createFB jcr exoplatform
   #createFB ecms exoplatform
   #createFB email-connector exoplatform
   #createFB dlp exoplatform
   #createFB agenda exoplatform
   #createFB agenda-connectors exoplatform
   #createFB digital-workplace exoplatform
   #createFB onlyoffice exoplatform
   #createFB saml2-addon exoplatform
   #createFB web-conferencing exoplatform
   #createFB jitsi-call exoplatform
   #createFB jitsi exoplatform
   #createFB multifactor-authentication exoplatform
   #createFB automatic-translation exoplatform
   #createFB documents exoplatform
   #createFB processes exoplatform
   #createFB data-upgrade exoplatform
   #createFB anti-bruteforce exoplatform
   #createFB anti-malware exoplatform
   #createFB external-visio-connector exoplatform
   #createFB caldav-integration exoplatform
   #createFB platform-private-distributions exoplatform
   #createFB platform-public-distributions exoplatform


popd

echo
printf "\e[1;33m# %s\e[m\n" "Feature branch ${FBRANCH} created"