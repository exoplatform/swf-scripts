#!/bin/bash -eu
# Args:
# FB_NAME: Mandatory -> Feature Branch name ( without feature/)

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
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_${FB_NAME}.groovy" --output fblist.txt
cat fblist.txt | grep "project:" >fblistfiltred.txt

echo "Done. Performing action..."

while IFS= read -r line; do
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]" | xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    [ ! -z "${MODULES}" ] && [[ ! "$(echo ${MODULES} | sed 's/,/ /g')" =~ "${item}" ]] && continue
    [ $org = "juzu" ] && continue
    echo "Unlocking protection on $org/$item:feature/${FB_NAME}"
    set +e
    curl -f -XDELETE -L "https://api.github.com/repos/$org/$item/branches/feature/${FB_NAME}/protection" \
        --header 'Accept: application/vnd.github.luke-cage-preview+json' \
        --header "Authorization: Bearer ${GIT_TOKEN}"
    set -e
    echo "OK. You have ${DELAY} minutes to perform actions. Please hurry up ! :xD"
    echo "Waiting ${DELAY} minutes..."
    sleep ${DELAY}m
    echo "Time's up! Restoring branch protection."
    curl -f -XPUT -L "https://api.github.com/repos/$org/$item/branches/feature/${FB_NAME}/protection" \
        --header 'Accept: application/vnd.github.luke-cage-preview+json' \
        --header "Authorization: Bearer ${GIT_TOKEN}" \
        --header 'Content-Type: application/json' \
        -d '{"required_status_checks":{"strict": true,"contexts": ["exo-ci/build-status"]},"required_pull_request_reviews":{"dismissal_restrictions": {},"dismiss_stale_reviews": true,"require_code_owner_reviews": false,"required_approving_review_count": 1}, "allow_force_pushes":true,"enforce_admins":false,"restrictions":null}' &>/dev/null
    echo "Branch is now protected!"    
done <fblistfiltred.txt
