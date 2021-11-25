#!/bin/bash -eu
# Args:
# Generate changelog of Maintenance release as Tribe Space Activity

modules=$(curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/${TASK_ID}.json")

body=""
plf_range=""
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
    [ "${item}" = "community-website" ] && continue
    [ "${item}" = "juzu" ] && continue
    [ "${item}" = "ert-contract" ] && continue
    #[[ "${version}" =~ .*-\$\{release-version\}$ ]] || continue
    git clone git@github.com:${org}/$item &>/dev/null
    pushd $item &>/dev/null
    git fetch --tags --prune &>/dev/null
    set +e
    tag_name=${version}
    before_tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -oP ^[1-9].[0-9].[0-9]$ | grep -B 1 ${version} | head -1)
    if [ -z "$tag_name" ] || [ -z "$before_tag_name" ]; then
      popd &>/dev/null
      continue
    fi
    echo "*** $item $before_tag_name -> $tag_name"
    commitIds=$(git log --no-merges --pretty=format:"%h" $before_tag_name~2...$tag_name~2 | xargs)
    subbody=""
    modulelink="https://github.com/$org/$item"
    [ $item == "platform-private-distributions" ] && plf_range="of $before_tag_name -> $tag_name"
    for commitId in $commitIds; do
        message=$(git show --pretty=format:%s -s $commitId | sed -E 's/\(#[0-9]+\)//g')
        echo $message | grep -q "Prepare Release" && continue
        echo $message | grep -q "continuous-release-template" && continue
        echo $message | grep -q "exo-release" && continue
        echo $message | grep -q "parent-pom" && continue
        #echo $message | grep -q "Merge Translation" && continue
        author=$(git show --format="%an" -s $commitId)
        commitLink="$modulelink/commit/$(git rev-parse $commitId)"
        elt=$(echo "<li>(<a href=\"$commitLink\">$commitId</a>) $message <b>$author</b></li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        echo "$commitLink $message $author"
        subbody="$subbody$elt"
    done
    [ -z "$subbody" ] || body="$body<li><b>$item</b> $before_tag_name -> $tag_name:\n\t<ul>\n\t$subbody</ul>\n\t</li>\n\t"
    set -e
    popd &>/dev/null
done
[ -z "$(echo $body | xargs)" ] && body="<p>The changelog $plf_range is empty now, but awesome things are coming... stay tuned :)</p>" || body="<ul>\n\t$body</ul>"
echo "Generating activity..."
curl --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/v1/social/spaces/${SPACE_ID}/activities" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"<p>Changelog generated $(date).</p>\n\n$body\n\",\"type\":\"\",\"templateParams\":{},\"files\":[]}" >/dev/null && echo OK
