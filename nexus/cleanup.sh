#!/bin/bash -eu
# This script removes old continuous deployment releases
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
MAVEN_DEPMGT_POM=21.0-exo
GATEIN_WCI=6.4.0-exo
KERNEL=6.4.0-exo
CORE=6.4.0-exo
WS=6.4.0-exo
GATEIN_PC=6.4.0-exo
GATEIN_SSO=6.4.0-exo
GATEIN_PORTAL=6.4.0-exo
PLATFORM_UI=6.4.0-exo
COMMONS=6.4.0-exo
SOCIAL=6.4.0-exo
GAMIFICATION=2.4.0-exo
GAMIFICATION_GITHUB=1.1.0-exo
KUDOS=2.4.0-exo
PERK_STORE=2.4.0-exo
WALLET=2.4.0-exo
APP_CENTER=2.4.0-exo
PUSH_NOTIFICATIONS=2.4.0-exo
ADDONS_MANAGER=2.4.0-exo
TASK=3.4.0-exo
ANALYTICS=1.3.0-exo
POLL=1.1.0-exo
NOTES=1.2.0-exo
MEEDS=1.4.0-exo
JCR=6.4.0
ECMS=6.4.0
AGENDA=1.3.0
CHAT_APPLICATION=3.4.0
DATA_UPGRADE=6.4.0
DIGITAL_WORKPLACE=1.4.0
LAYOUT_MANAGEMENT=1.4.0
NEWS=2.4.0
ONLYOFFICE=2.4.0
SAML2_ADDON=3.4.0
WEB_CONFERENCING=2.4.0
JITSI=1.3.0
JITSI_CALL=1.3.0
AUTOMATIC_TRANSLATION=1.1.0
DOCUMENTS=1.1.0
PROCESSES=1.1.0
MAIL_INTEGRATION=1.1.0
MULTIFACTOR_AUTHENTICATION=1.2.0
AGENDA_CONNECTORS=1.1.0
DLP=1.0.0
ANTI_MALWARE=1.0.0
ANTI_BRUTEFORCE=1.0.0
CLOUD_DRIVE_CONNECTORS=1.0.0
PLATFORM_PRIVATE_DISTRIBUTIONS=6.4.0
###### CWI
COMMUNITY_WEBSITE=6.4.0
#####
# Rest API Nexus repositories list
NEXUS_REPOSITORIES_LIST="exo-addons-releases exo-private-releases exo-releases cp-cwi-releases meeds-releases"

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
    echo " ($counter/${#releases_to_be_dropped[@]}) Dropping Release:  $PLATFORM_PRIVATE_DISTRIBUTIONS-$rel_suffix..."
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
    # eXo Addons (exo-addons-releases)
    do_delete_artifact_version "agenda" $AGENDA $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/agenda
    do_delete_artifact_version "chat-application" $CHAT_APPLICATION $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/chat
    do_delete_artifact_version "data-upgrade" $DATA_UPGRADE $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/upgrade
    do_delete_artifact_version "digital-workplace" $DIGITAL_WORKPLACE $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/digital-workplace
    do_delete_artifact_version "layout-management" $LAYOUT_MANAGEMENT $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/layout-management
    do_delete_artifact_version "news" $NEWS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/news
    do_delete_artifact_version "onlyoffice" $ONLYOFFICE $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/onlyoffice
    do_delete_artifact_version "saml2-addon" $SAML2_ADDON $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/sso/saml2-addon-*
    do_delete_artifact_version "web-conferencing" $WEB_CONFERENCING $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/web-conferencing
    do_delete_artifact_version "jitsi" $JITSI $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/jitsi
    do_delete_artifact_version "multifactor-authentication" $MULTIFACTOR_AUTHENTICATION $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/multifactor-authentication
    do_delete_artifact_version "automatic-translation" $AUTOMATIC_TRANSLATION $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/automatic-translation
    do_delete_artifact_version "documents" $DOCUMENTS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/documents
    do_delete_artifact_version "processes" $PROCESSES $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/processes
    do_delete_artifact_version "mail-integration" $MAIL_INTEGRATION $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/mail-integration
    do_delete_artifact_version "agenda-connectors" $AGENDA_CONNECTORS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/agenda-connectors
    do_delete_artifact_version "dlp" $DLP $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/dlp
    do_delete_artifact_version "cloud-drive-connectors" $CLOUD_DRIVE_CONNECTORS $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/addons/cloud-drive-connectors
    do_delete_artifact_version "anti-malware" $ANTI_MALWARE $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/anti-malware
    do_delete_artifact_version "anti-bruteforce" $ANTI_BRUTEFORCE $rel_suffix $BASE_PATH_HOSTED/exo-addons-releases org/exoplatform/anti-bruteforce
    # eXo Addons (exo-releases)
    do_delete_artifact_version "jcr" $JCR $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/jcr
    do_delete_artifact_version "ecms" $ECMS $rel_suffix $BASE_PATH_HOSTED/exo-releases org/exoplatform/ecms
    # eXo Packaging (exo-private-releases)    
    do_delete_artifact_version "platform-private-distributions" $PLATFORM_PRIVATE_DISTRIBUTIONS $rel_suffix $BASE_PATH_HOSTED/exo-private-releases/com/exoplatform/platform/distributions
    # eXo CWI (cp-cwi-releases)    
    do_delete_artifact_version "community-website" $COMMUNITY_WEBSITE $rel_suffix $BASE_PATH_HOSTED/cp-cwi-releases org/exoplatform/community
    ((counter++))
done

# Rest API Call 
for repository in ${NEXUS_REPOSITORIES_LIST}; do
    do_delete_curl "service/local/metadata/repositories/${repository}/content"
    do_delete_curl "service/local/data_index/repositories/${repository}/content"
done

# Empty Trash
do_empty_trash