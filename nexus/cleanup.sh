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

NB_RELEASES_TO_KEEP=0 # Nothing in month
CURRENT_MONTH="11"
CURRENT_YEAR=2022
BASE_PATH=/srv/nexus/storage
BASE_PATH_HOSTED=$BASE_PATH/hosted

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
    echo "gamification-github:$GAMIFICATION_GITHUB-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/gamification-github -type d -name $GAMIFICATION_GITHUB-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
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
    echo "jcr:$JCR-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/jcr -type d -name $JCR-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "ecms:$ECMS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/ecms -type d -name $ECMS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "agenda:$AGENDA-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/agenda -type d -name $AGENDA-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "chat-application:$CHAT_APPLICATION-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/chat -type d -name $CHAT_APPLICATION-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "data-upgrade:$DATA_UPGRADE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/upgrade -type d -name $DATA_UPGRADE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "digital-workplace:$DIGITAL_WORKPLACE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/digital-workplace -type d -name $DIGITAL_WORKPLACE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "layout-management:$LAYOUT_MANAGEMENT-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/layout-management -type d -name $LAYOUT_MANAGEMENT-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "news:$NEWS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/news -type d -name $NEWS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "onlyoffice:$ONLYOFFICE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/onlyoffice -type d -name $ONLYOFFICE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "saml2-addon:$SAML2_ADDON-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/sso/saml2-addon-* -type d -name $SAML2_ADDON-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "task:$TASK-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/task -type d -name $TASK-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "web-conferencing:$WEB_CONFERENCING-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/web-conferencing -type d -name $WEB_CONFERENCING-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "jitsi:$JITSI-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/jitsi -type d -name $JITSI-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "analytics:$ANALYTICS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/analytics -type d -name $ANALYTICS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "multifactor-authentication:$MULTIFACTOR_AUTHENTICATION-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/multifactor-authentication -type d -name $MULTIFACTOR_AUTHENTICATION-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "automatic-translation:$AUTOMATIC_TRANSLATION-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/automatic-translation -type d -name $AUTOMATIC_TRANSLATION-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "documents:$DOCUMENTS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/documents -type d -name $DOCUMENTS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "processes:$PROCESSES-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/processes -type d -name $PROCESSES-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "poll:$POLL-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/poll -type d -name $POLL-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "mail-integration:$MAIL_INTEGRATION-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/mail-integration -type d -name $MAIL_INTEGRATION-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "notes:$NOTES-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-releases/org/exoplatform/addons/notes -type d -name $NOTES-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "agenda-connectors:$AGENDA_CONNECTORS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/agenda-connectors -type d -name $AGENDA_CONNECTORS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "dlp:$DLP-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/dlp -type d -name $DLP-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "cloud-drive-connectors:$CLOUD_DRIVE_CONNECTORS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/addons/cloud-drive-connectors -type d -name $CLOUD_DRIVE_CONNECTORS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "anti-malware:$ANTI_MALWARE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/anti-malware -type d -name $ANTI_MALWARE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "anti-bruteforce:$ANTI_BRUTEFORCE-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-addons-releases/org/exoplatform/anti-bruteforce -type d -name $ANTI_BRUTEFORCE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "platform-private-distributions:$PLATFORM_PRIVATE_DISTRIBUTIONS-$rel_suffix"
    find $BASE_PATH_HOSTED/exo-private-releases/com/exoplatform/platform/distributions -type d -name $PLATFORM_PRIVATE_DISTRIBUTIONS-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    echo "community-website:$COMMUNITY_WEBSITE-$rel_suffix"
    find $BASE_PATH_HOSTED/cp-cwi-releases/org/exoplatform/community -type d -name $COMMUNITY_WEBSITE-$rel_suffix -exec rm -rvf {} \; 2>/dev/null || true
    ((counter++))
done

# Rest API Call 
for repository in ${NEXUS_REPOSITORIES_LIST}; do
    do_delete_curl "service/local/metadata/repositories/${repository}/content"
    do_delete_curl "service/local/data_index/repositories/${repository}/content"
done