#!/bin/bash -eu
# This script removes old continuous deployment releases of meed distribution
# Requried Env vars:
# NEXUS_ADMIN: admin's username
# NEXUS_PASSWORD: admin's password
# NEXUS_URL: Nexus URL with https://
#####

get_suffix() {
    echo $1 | cut -d '-' -f3
}

do_delete_curl() {
    curl -u $NEXUS_ADMIN:$NEXUS_PASSWORD -X "DELETE" -w "%{http_code}" "$NEXUS_URL/$1"
}

NB_RELEASES_TO_KEEP=0 # Nothing in month
CURRENT_MONTH="09"
CURRENT_YEAR=2022
BASE_PATH=/srv/nexus/storage
BASE_PATH_HOSTED=$BASE_PATH/hosted

######################
##Modules
MAVEN_DEPMGT_POM=21.0-meed
GATEIN_WCI=6.4.0-meed
KERNEL=6.4.0-meed
CORE=6.4.0-meed
WS=6.4.0-meed
GATEIN_PC=6.4.0-meed
GATEIN_SSO=6.4.0-meed
GATEIN_PORTAL=6.4.0-meed
PLATFORM_UI=6.4.0-meed
COMMONS=6.4.0-meed
SOCIAL=6.4.0-meed
GAMIFICATION=2.4.0-meed
KUDOS=2.4.0-meed
PERK_STORE=2.4.0-meed
WALLET=2.4.0-meed
APP_CENTER=2.4.0-meed
PUSH_NOTIFICATIONS=2.4.0-meed
ADDONS_MANAGER=2.4.0-meed
MEEDS=1.4.0-meed
TASK=3.4.0-meed
ANALYTICS=1.3.0-meed
POLL=1.1.0-meed
NOTES=1.2.0-meed
######
# Non-product modules
DEEDS_DAPP=1.0.0-meed
DEEDS_TENANT=1.0.0-meed
#####
# Rest API Nexus repositories list
NEXUS_REPOSITORIES_LIST="exo-addons-releases exo-releases meeds-releases"

# Fetch releases 
releases=($(cat "$BASE_PATH_HOSTED/exo-releases/org/exoplatform/maven-depmgt-pom/maven-metadata.xml" | grep -oP $MAVEN_DEPMGT_POM-${CURRENT_YEAR}${CURRENT_MONTH}[0-9][0-9] | sort --version-sort | uniq | xargs))
echo "Available releases are:"
echo ${releases[@]}
if [ ${#releases[@]} -le $NB_RELEASES_TO_KEEP ]; then
    echo "Releases number (${#releases[@]}) does not exceed the maximum quota ($NB_RELEASES_TO_KEEP). Nothing to do."
    exit 0
fi
echo "OK, Let's start the cleanup! :-)"
releases_to_be_dropped=("${releases[@]:$NB_RELEASES_TO_KEEP}")
echo "Releases to be dropped are:"
echo ${releases_to_be_dropped[@]}
counter=1
for release in ${releases_to_be_dropped[@]}; do
    rel_suffix=$(get_suffix $release)
    echo "==========================================================================================="
    echo " ($counter/${#releases_to_be_dropped[@]}) Dropping Release:  $MEEDS-$rel_suffix..."
    echo "==========================================================================================="
    echo "maven-depmgt-pom:$MAVEN_DEPMGT_POM-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/maven-depmgt-pom -type d -name $MAVEN_DEPMGT_POM-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "gatein-wci:$GATEIN_WCI-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/gatein/wci -type d -name $GATEIN_WCI-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "kernel:$KERNEL-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/kernel -type d -name $KERNEL-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "core:$CORE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/core -type d -name $CORE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "ws:$WS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/ws -type d -name $WS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "gatein-pc:$GATEIN_PC-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/gatein/pc -type d -name $GATEIN_PC-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "gatein-sso:$GATEIN_SSO-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/gatein/sso -type d -name $GATEIN_SSO-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "gatein-portal:$GATEIN_PORTAL-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/gatein/portal -type d -name $GATEIN_PORTAL-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "platform-ui:$PLATFORM_UI-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/platform-ui -type d -name $PLATFORM_UI-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "commons:$COMMONS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/commons -type d -name $COMMONS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "social:$SOCIAL-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/social -type d -name $SOCIAL-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "gamification:$GAMIFICATION-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/gamification -type d -name $GAMIFICATION-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "kudos:$KUDOS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/kudos -type d -name $KUDOS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "perk-store:$PERK_STORE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/perk-store -type d -name $PERK_STORE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "wallet:$WALLET-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/wallet -type d -name $WALLET-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "app-center:$APP_CENTER-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/app-center -type d -name $APP_CENTER-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "push-notifications:$PUSH_NOTIFICATIONS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/push-notifications -type d -name $PUSH_NOTIFICATIONS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "addons-manager:$ADDONS_MANAGER-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/platform/addons-manager -type d -name $ADDONS_MANAGER-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "meeds:$MEEDS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/io/meeds/distribution -type d -name $MEEDS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "task:$TASK-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/task -type d -name $TASK-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "analytics:$ANALYTICS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/analytics -type d -name $ANALYTICS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "poll:$POLL-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/poll -type d -name $POLL-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "notes:$NOTES-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/addons/notes -type d -name $NOTES-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "deeds-dapp:$DEEDS_DAPP-$rel_suffix"
    find $BASE_PATH/meeds-releases/io/meeds/deeds-dapp -type d -name $DEEDS_DAPP-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "deeds-tenant:$DEEDS_TENANT-$rel_suffix"
    find $BASE_PATH/meeds-releases/io/meeds/deeds-tenant -type d -name $DEEDS_TENANT-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    ((counter++))
done

# Rest API Call 
for repository in ${NEXUS_REPOSITORIES_LIST}; do
    do_delete_curl "service/local/metadata/repositories/${repository}/content"
    do_delete_curl "service/local/data_index/repositories/${repository}/content"
done