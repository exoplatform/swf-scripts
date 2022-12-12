#!/bin/bash -eu
# This script removes old continuous deployment releases of meed distribution
# Requried Env vars:
# NEXUS_ADMIN: admin's username
# NEXUS_PASSWORD: admin's password
# NEXUS_URL: Nexus URL with https://
#####

get_suffix() {
    echo $1 | grep -o '[^-]*$'
}

do_delete_curl() {
    curl -u $NEXUS_ADMIN:$NEXUS_PASSWORD -X "DELETE" -w "%{http_code}" "$NEXUS_URL/$1"
}

do_empty_trash() {
    do_delete_curl "service/local/wastebasket"
}

do_delete_artifact_version() {
    module_name="$1"
    version_preffix="$2"
    version_suffix="$3"
    storage_dir="$4"
    artifact_dir="$5"
    echo "$module_name:$version_preffix-$version_suffix"
    find "$storage_dir/$artifact_dir" -type d -name $version_preffix-$version_suffix | while read dirname; do
        relativePath=$(echo $dirname | sed "s|$storage_dir/$artifact_dir|$storage_dir/./$artifact_dir|g")
        relativeAttributesPath=$(echo $dirname | sed "s|$storage_dir/$artifact_dir|$storage_dir/$NEXUS_ATTRIBUTES_FOLDER/./$artifact_dir|g")
        attributesPath=$(echo $dirname | sed "s|$storage_dir/$artifact_dir|$storage_dir/$NEXUS_ATTRIBUTES_FOLDER/$artifact_dir|g")
        rsync -avPR "$relativePath" $storage_dir/$NEXUS_TRASH_FOLDER/
        rsync -avPR "$relativeAttributesPath" $storage_dir/$NEXUS_TRASH_FOLDER/$NEXUS_ATTRIBUTES_FOLDER/
        rm -rvf $dirname
        rm -rvf $attributesPath
    done
    chown 200:200 -R $storage_dir/$NEXUS_TRASH_FOLDER/$NEXUS_ATTRIBUTES_FOLDER/
}

NB_RELEASES_TO_KEEP=0 # Nothing in month
CURRENT_MONTH="11"
CURRENT_YEAR=2022
BASE_PATH=/srv/nexus/storage
BASE_PATH_HOSTED=$BASE_PATH/hosted
NEXUS_ATTRIBUTES_FOLDER=".nexus/attributes"
NEXUS_TRASH_FOLDER=".nexus/trash"

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
GAMIFICATION_GITHUB=1.1.0-meed
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
DEEDS_TENANT_PROVISIONING=1.0.0-meed
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
    # Meeds Core (exo-releases)
    do_delete_artifact_version "maven-depmgt-pom" $MAVEN_DEPMGT_POM $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/maven-depmgt-pom
    do_delete_artifact_version "kernel" $KERNEL $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/kernel
    do_delete_artifact_version "core" $CORE $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/core
    do_delete_artifact_version "ws" $WS $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/ws
    do_delete_artifact_version "gatein-pc" $GATEIN_PC $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/gatein/pc
    do_delete_artifact_version "gatein-wci" $GATEIN_WCI $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/gatein/wci
    do_delete_artifact_version "gatein-sso" $GATEIN_SSO $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/gatein/sso
    do_delete_artifact_version "gatein-portal" $GATEIN_PORTAL $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/gatein/portal
    do_delete_artifact_version "gatein-portal" $GATEIN_PORTAL $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/gatein/portal
    do_delete_artifact_version "platform-ui" $PLATFORM_UI $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/platform-ui
    do_delete_artifact_version "commons" $COMMONS $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/commons
    do_delete_artifact_version "social" $SOCIAL $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/social
    # Meeds Addons (exo-addons-releases)
    do_delete_artifact_version "gamification" $GAMIFICATION $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/gamification
    do_delete_artifact_version "gamification-github" $GAMIFICATION_GITHUB $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/gamification-github
    do_delete_artifact_version "kudos" $KUDOS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/kudos
    do_delete_artifact_version "perk-store" $PERK_STORE $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/perk-store
    do_delete_artifact_version "wallet" $WALLET $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/wallet
    do_delete_artifact_version "app-center" $APP_CENTER $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/app-center
    do_delete_artifact_version "push-notifications" $PUSH_NOTIFICATIONS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/push-notifications
    do_delete_artifact_version "poll" $POLL $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/poll
    do_delete_artifact_version "task" $TASK $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/task
    do_delete_artifact_version "analytics" $ANALYTICS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/analytics
    # Meeds Addons (exo-releases)
    do_delete_artifact_version "notes" $NOTES $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/addons/notes
    do_delete_artifact_version "addons-manager" $ADDONS_MANAGER $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/platform/addons-manager
    # Meeds Packaging (exo-releases)
    do_delete_artifact_version "meeds" $MEEDS $rel_suffix $BASE_PATH_HOSTED/exo-releases io/meeds/distribution
    # Meeds Third party (meeds-releases)
    do_delete_artifact_version "deeds-dapp" $DEEDS_DAPP $rel_suffix $BASE_PATH/meeds-releases io/meeds/deeds-dapp
    do_delete_artifact_version "deeds-tenant" $DEEDS_TENANT $rel_suffix $BASE_PATH/meeds-releases io/meeds/deeds-tenant
    # Meeds Private Third party (meeds-private-releases)
    do_delete_artifact_version "deeds-tenant-provisioning" $DEEDS_TENANT_PROVISIONING $rel_suffix $BASE_PATH/meeds-private-releases io/meeds/deeds-tenant-provisioning    
    ((counter++))
done

# Rest API Call 
for repository in ${NEXUS_REPOSITORIES_LIST}; do
    do_delete_curl "service/local/metadata/repositories/${repository}/content"
    do_delete_curl "service/local/data_index/repositories/${repository}/content"
done

# Empty Trash
do_empty_trash