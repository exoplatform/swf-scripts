#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD as Tribe Space Activity

modules=$(curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/continuous-release-template.json")

body=""
echo "Done. Performing action..."
for module in $(echo "${modules}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${module} | base64 --decode | jq -r ${1}
    }
    item=$(_jq '.name')
    org=$(_jq '.git_organization')
    version=$(_jq '.release.version')
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue
    [[ "${version}" =~ .*-\$\{release-version\}$ ]] || continue
    git clone git@github.com:${org}/$item
    pushd $item &>/dev/null
    git fetch --tags --prune &>/dev/null
    tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -P .*-[0-9]{8}$ | tail -1)
    before_tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -P .*-[0-9]{8}$ | tail -2 | head -1)
    echo "*** $item $before_tag_name -> $tag_name"
    set +e
    commitIds=$(git log --no-merges --pretty=format:"%h" $before_tag_name~2...$tag_name~2 | xargs)
    subbody=""
    modulelink="https://github.com/$org/$item"
    for commitId in $commitIds; do
        message=$(git show --pretty=format:%s -s $commitId | sed -E 's/\(#[0-9]+\)//g')
        echo $message | grep -q "Prepare Release" && continue
        echo $message | grep -q "continuous-release-template" && continue
        echo $message | grep -q "exo-release" && continue
        #echo $message | grep -q "parent-pom" && continue
        #echo $message | grep -q "Merge Translation" && continue
        author=$(git show --format="%an" -s $commitId)
        commitLink="$modulelink/commit/$(git rev-parse $commitId)"
        elt=$(echo "<li>(<a href=\"$commitLink\">$commitId</a>) $message <b>$author</b></li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        echo "$commitLink $message $author"
        subbody="$subbody$elt"
    done
    [ -z "$subbody" ] || body="$body<li>$item $before_tag_name -> $tag_name\n\t<ul>\n\t$subbody</ul>\n\t</li>\n\t"
    set -e
    popd &>/dev/null
done

echo "Generating activity..."
curl --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/v1/social/spaces/${SPACE_ID}/activities" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"<p>Changelog generated $(date)</p>\n\n<ul>\n\t$body</ul>\n\",\"type\":\"\",\"templateParams\":{},\"files\":[]}" >/dev/null && echo OK
