#!/bin/bash -eu
# Requires MAX_DAYS_TOKEEP : max days number to keep pr opened.

convert2json() {
    echo "["$(cat /tmp/prlist.txt | grep -o -P '(?<=\[).*(?=, privacy:)' | sed -e "s/$/ },/" -e "s/^/{ /g" -e 's/project/"project"/g' -e 's/gitOrganization/"gitOrganization"/g') "]" | sed -e "s/'/\"/g" -e "s/, ]/]/g" | jq -r '.[] | @base64'
}

echo "Parsing PR Seed Job Configuration..."

current_date=$(date '+%s')
echo "Parsing releases branch from catalog..."
rm -f /tmp/prlist.txt &>/dev/null
curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/PR/seed_jobs_pr.groovy" --output /tmp/prlist.txt

items=$(convert2json)

echo "Done. Performing action..."
for row in ${items}; do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }
    item="$(_jq '.project')"
    org="$(_jq '.gitOrganization')"
    echo "Fetching open pull request of $org/$item...."
    prs=$(curl -s -f -XGET -L "https://api.github.com/repos/$org/$item/pulls?state=open" \
        --header 'Accept: application/vnd.github.luke-cage-preview+json' \
        --header "Authorization: Bearer ${GIT_TOKEN}" | jq -r '.[] | @base64')
    echo "Done."
    for pr in ${prs}; do
        set +e
        _jqpr() {
            echo ${pr} | base64 --decode | jq -r ${1}
        }
        number="$(_jqpr '.number')" || continue
        set -e
        title="$(_jqpr '.title')"
        updated_at="$(_jqpr '.updated_at')"
        epoch_updated_date="$(date -d $updated_at '+%s')"
        diff_in_days=$(((current_date - epoch_updated_date) / (60 * 60 * 24)))
        if [ $diff_in_days -gt $MAX_DAYS_TOKEEP ]; then
            curl -s -XPATCH -L "https://api.github.com/repos/$org/$item/pulls/$number" \
            --header 'Accept: application/vnd.github.v3+json' \
                --header "Authorization: Bearer ${GIT_TOKEN}" \
                -d '{"state":"closed"}' &>/dev/null
            echo "PR: $org/$item/$number has been closed. Its latest update date is: $updated_at"
        else
            echo "PR: $org/$item/$number is Keeped. Its latest update date is: $(date -d $updated_at '+%Y-%m-%d %H:%M:%S'), Remaining days is: $((MAX_DAYS_TOKEEP - diff_in_days))"
        fi
    done
    echo "Done fetching prs of $org/$item."
done
