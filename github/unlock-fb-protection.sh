#!/bin/bash -eu
# Args:
# FB_NAME: Mandatory -> Feature Branch name ( without feature/)

##
# Determines if a value exists in an array.
###
function hasArrayValue() {
    local needle="$1"
    shift 1
    local haystack="$@"
    printf '%s\n' "${haystack[@]}" | grep -q "${needle}"
}

echo "Parsing FB ${FB_NAME} Seed Job Configuration..."

[ -z "${FB_NAME}" ] && exit 1

set +u
[ -z "${MODULES}" ] && exit 1
[ -z "${DELAY}" ] && DELAY=5
set -u

# Check gh command is installed
hash gh 2>/dev/null

current_date=$(date '+%s')
echo "Parsing FB repositories from catalog..."
fblist=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_$(echo ${FB_NAME//-/} | tr '[:upper:]' '[:lower:]').groovy" | grep "project:")
modules_length=$(echo $fblist | grep -o 'project:' | wc -w)
echo "Modules count: ${modules_length}"

if [ -z "${MODULES}" ]; then
    echo "No modules specified!"
    exit 1
fi
echo "Done. Checking modules..."
MODULES="$(echo ${MODULES} | sed 's/,/ /g')"
MODULES_LENGTH="$(echo ${MODULES} | wc -w)"
# Check phase
counter=0
while IFS=']' read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]" | xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    hasArrayValue "${org}/$item" ${MODULES} && counter=$((counter + 1)) || continue
done <<<"$fblist"
if [ "${counter}" -ne "${MODULES_LENGTH}" ]; then
    echo "Error Checks failed! Abort"
    exit 1
fi
echo "Checks Done. Performing unlock protection..."
for module in $MODULES; do
    echo "Unlocking protection on $module:feature/${FB_NAME}"
    set +e
    gh api --method DELETE -H 'Accept: application/vnd.github.luke-cage-preview+json' "/repos/$module/branches/feature/${FB_NAME}/protection"
    set -e
done
echo "Branches unlocked!"
echo "OK. You have ${DELAY} minutes to perform actions. Please hurry up ! :xD"
echo "Waiting ${DELAY} minutes..."
sleep ${DELAY}m
echo "Time's up! Restoring branch protection."
for module in $MODULES; do
    echo "Restoring protection on $module:feature/${FB_NAME}"
    curl -f -XPUT -L "https://api.github.com/repos/$module/branches/feature/${FB_NAME}/protection" \
        --header 'Accept: application/vnd.github.luke-cage-preview+json' \
        --header "Authorization: Bearer ${GH_TOKEN}" \
        --header 'Content-Type: application/json' \
        -d '{"required_status_checks":{"strict": true,"contexts": ["exo-ci/build-status"]},"required_pull_request_reviews":{"dismissal_restrictions": {},"dismiss_stale_reviews": true,"require_code_owner_reviews": false,"required_approving_review_count": 1}, "allow_force_pushes":true,"enforce_admins":false,"restrictions":null}' &>/dev/null
done
echo "Branches now protected!"
