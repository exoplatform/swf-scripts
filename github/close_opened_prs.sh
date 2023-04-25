#!/bin/bash -eu
# Requires MAX_DAYS_TOKEEP : max days number to keep pr opened.

echo "Parsing PR Seed Job Configuration..."

current_date=$(date '+%s')
prModules=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/PR/seed_jobs_pr.groovy" | grep "project:")

modules_length=$(echo $prModules | grep -o 'project:' | wc -w)
echo "Modules count: ${modules_length}"
counter=0
echo "Done. Performing action..."
while IFS=']' read -r line; do
    counter=$((counter+1))  
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    echo "(${counter}/${modules_length}) Fetching open pull request of $org/$item...."
    prs=$(gh api -X GET "/repos/$org/$item/pulls?state=open" | jq -r '.[] | @base64')
    echo "Done."
    for pr in ${prs}; do
        set +e
        _jqpr() {
            echo ${pr} | base64 --decode | jq -r ${1}
        }
        number="$(_jqpr '.number')" || continue
        ref="$(_jqpr '.head.ref')" || continue
        set -e
        title="$(_jqpr '.title')"
        updated_at="$(_jqpr '.updated_at')"
        epoch_updated_date="$(date -d $updated_at '+%s')"
        diff_in_days=$(((current_date - epoch_updated_date) / (60 * 60 * 24)))
        if [ $diff_in_days -gt $MAX_DAYS_TOKEEP ]; then
            gh api -X DELETE "/repos/$org/$item/git/refs/heads/${ref}" >/dev/null
            gh api -X POST "/repos/$org/$item/issues/$number/comments" -f body='Stale PR. Closed' >/dev/null
            echo "PR: $org/$item/$number: \"${title}\" has been closed. Latest update date: $updated_at"
        else
            echo "PR: $org/$item/$number: \"${title}\" is Kept. Latest update date: $(date -d $updated_at '+%Y-%m-%d %H:%M:%S'). Stale Remaining days: $((MAX_DAYS_TOKEEP - diff_in_days))"
        fi
    done
    echo "Done fetching prs of $org/$item."
done <<< "$prModules"
