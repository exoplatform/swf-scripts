#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD as Tribe Space Activity

modules=$(curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/continuous-release-template.json")

body=""
plf_range=""
grafana_dashboard="https://mon.exoplatform.org/d/g5gmgcpnz/deployed-exo-version"
echo "Done. Performing action..."
git clone git@github.com:exoplatform/platform-private-distributions &>/dev/null
pushd platform-private-distributions &>/dev/null
tag_name_suffix=RC07
before_tag_name_suffix=M01
plfVersion=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 6.3.0-${tag_name_suffix}$ )
popd &>/dev/null
rm -rf platform-private-distributions &>/dev/null
changelogfile="/tmp/CHANGE_LOG.txt"
echo "=== Changelog generated $(date)" > $changelogfile
echo "platform version: ${plfVersion}" >> $changelogfile
echo "===" >> $changelogfile
echo "" >> $changelogfile
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
    [[ "${version}" =~ .*-\$\{release-version\}$ ]] || continue
    git clone git@github.com:${org}/$item &>/dev/null
    pushd $item &>/dev/null
    git fetch --tags --prune &>/dev/null
    set +e
    currentversion=$(echo $version | sed 's/\-\${release-version}//g' | sed 's/-version//g')
    tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep $currentversion-${tag_name_suffix}$ )
    before_tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep $currentversion-${before_tag_name_suffix}$)
    if [ -z "$tag_name" ] || [ -z "$before_tag_name" ]; then
      popd &>/dev/null
      continue
    fi
    echo "*** $item $before_tag_name -> $tag_name"
    commitIds=$(git log --no-merges --pretty=format:"%H" $before_tag_name~2...$tag_name~2 | xargs)
    commitstats=$(git log --no-merges --numstat --pretty="%H" $before_tag_name~2...$tag_name~2 | awk 'NF==3 {plus+=$1; minus+=$2} END {printf("+%d, -%d\n", plus, minus)}')
    subbody=""
    modulelink="https://github.com/$org/$item"
    [ $item == "platform-private-distributions" ] && plf_range="of $before_tag_name -> $tag_name"
    [ -z "$commitIds" ] || echo "*** $item $before_tag_name -> $tag_name" >> $changelogfile
    for commitId in $commitIds; do
        message=$(git show --pretty=format:%s -s $commitId | sed -E 's/\(#[0-9]+\)//g' | xargs -0)
        echo $message | grep -q "Prepare Release" && continue
        echo $message | grep -q "continuous-release-template" && continue
        echo $message | grep -q "exo-release" && continue
        echo $message | grep -q "parent-pom" && continue
        echo $message | grep -q "eXo Tasks notifications" && continue
        echo $message | grep -q "Specify base branch when merging PR for eXo Tasks notifications" && continue
        #echo $message | grep -q "Merge Translation" && continue
        author=$(git show --format="%an" -s $commitId | sed 's/exo-swf/eXo Software Factory/g' | xargs)
        commitLink="$modulelink/commit/$(git rev-parse $commitId)"
        fomattedCommitId=$(echo $commitId | head -c 7)
        elt=$(echo "<li>(<a href=\"$commitLink\">$fomattedCommitId</a>) $message <b>$author</b></li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        echo "$commitLink $message *** $author"
        echo "	($fomattedCommitId) $message --- $author" >> $changelogfile
        subbody="$subbody$elt"
    done
    beforeTagCommitID=$(git rev-parse --short $before_tag_name~2)
    tagCommitID=$(git rev-parse --short $tag_name~2)
    fullchangeloglink=$(echo "<a href=\"https://github.com/${org}/${item}/compare/${beforeTagCommitID}...${tagCommitID}\">$before_tag_name..$tag_name</a>" | gawk '{ gsub(/"/,"\\\"") } 1')
    [ -z "$subbody" ] || body="$body<li><b>$item</b> ${fullchangeloglink} (${commitstats}):\n\t<ul>\n\t$subbody</ul>\n\t</li>\n\t"
    set -e
    popd &>/dev/null
done
[ -z "$(echo $body | xargs)" ] && echo "-- No changelog for this release." >> $changelogfile
echo "" >> $changelogfile
echo "===" >> $changelogfile
[ -z "$(echo $body | xargs)" ] && body="<p>The changelog $plf_range is empty now, but awesome things are coming... stay tuned :)</p>" || body="<ul>\n\t$body</ul>"
dep_status=$(echo "Deployment status: \n\t\n\t<a href=\"$grafana_dashboard\">Grafana Dashboard</a>.\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
#yearnotif=$(echo "<br/><br/>This is the <b>latest changelog</b> of $(date +%Y)! See you next year! 🎊 🎊 🥳 🥳\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
changeloghash=$(echo '<a target="_blank" class="metadata-tag" rel="noopener" title="Start a search based on this tag">#Changelog</a>' | gawk '{ gsub(/"/,"\\\"") } 1')
cicdhash=$(echo '<a target="_blank" class="metadata-tag" rel="noopener" title="Start a search based on this tag">#cicd</a>' | gawk '{ gsub(/"/,"\\\"") } 1')
uploadlink="${STORAGE_URL}/$(echo ${plfVersion} | grep -oP ^[0-9]\.[0-9])/${plfVersion}/"
# Sanitize pwd
downloadlink="$(echo ${uploadlink}$(basename $changelogfile) | sed 's|private/|public/|g' | sed -E 's|//\w+:\w+@|//|')"
echo "Download link: $downloadlink"
downloadinfo=''
if wget -S --spider $downloadlink &>/dev/null; then
  downloadinfo=$(echo "Changelog file: \n\t\n\t<a href=\"$downloadlink\">link</a>.<br/>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
fi
body=$body$downloadinfo
body=$body$dep_status #$yearnotif
curl -T ${changelogfile} ${uploadlink}
echo "Generating activity..."
for SPACE_ID in ${SPACES_IDS/,/ }; do
  curl --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/v1/social/spaces/${SPACE_ID}/activities" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"<p>${changeloghash} ${cicdhash} generated $(date).</p>\n\n$body\n\",\"type\":\"\",\"templateParams\":{},\"files\":[]}" >/dev/null && echo OK
done