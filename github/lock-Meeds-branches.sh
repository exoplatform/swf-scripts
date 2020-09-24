#/bin/bash -eu

[ ${OPERATION} = "LOCK" ] && review_count=6 || review_count=1

echo "Operation \"${OPERATION}\" will be performed..."

echo "Getting Meeds-io repositories..."
items=$(curl -f -XGET -L "https://api.github.com/orgs/meeds-io/repos" \
    --header 'Accept: application/vnd.github.v3+json' \
    --header "Authorization: Bearer ${GIT_TOKEN}" | jq -r '.[] | @base64')
echo "Done. Performing action..."
for row in ${items}; do
    _jq() {
        echo ${row} | base64 --decode | jq -r ${1}
    }
    item="$(_jq '.name')/branches/$(_jq '.default_branch')"
    echo $item | sed 's|branches/||g'
    curl -f -XPATCH -L "https://api.github.com/repos/meeds-io/$item/protection/required_pull_request_reviews" \
        --header 'Accept: application/vnd.github.luke-cage-preview+json' \
        --header "Authorization: Bearer ${GIT_TOKEN}" \
        --header 'Content-Type: application/json' \
        -d "{\"required_approving_review_count\": ${review_count}}"
done
