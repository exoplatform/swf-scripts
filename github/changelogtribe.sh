#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD

# 2 max commit after released dev commit (generated commits swf release)
MAX_RELEASE_COMMITS_FETCH_DEPTH=2
MAX_COMMITS_LISTING_PER_MODULE=15

modules=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/continuous-release-template-exo.json")

body=""
plf_range=""
echo "Done. Performing action..."
git clone git@github.com:exoplatform/platform-private-distributions &>/dev/null
pushd platform-private-distributions &>/dev/null
tag_name_suffix=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -Pv '(exo|meed)' | grep -oP [0-9]{8}$ | tail -1)
before_tag_name_suffix=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -Pv '(exo|meed)' | grep -oP [0-9]{8}$ | tail -2 | head -1)
plfVersion=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -Pv '(exo|meed)' | grep -P .*-${tag_name_suffix}$)
popd &>/dev/null
rm -rf platform-private-distributions &>/dev/null
changelogfile="/tmp/CHANGE_LOG.txt"
echo "=== Changelog generated $(date)" >$changelogfile
echo "platform version: ${plfVersion}" >>$changelogfile
echo "===" >>$changelogfile
echo "" >>$changelogfile
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
  git clone git@github.com:${org}/$item &>/dev/null
  pushd $item &>/dev/null
  git fetch --tags --prune &>/dev/null
  set +e
  if [ ${org,,} != "meeds-io" ]; then
    tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -Pv '(exo|meed)' | grep -P .*-${tag_name_suffix}$)
    before_tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep -Pv '(exo|meed)' | grep -P .*-${before_tag_name_suffix}$)
  else
    tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'exo' | grep -P .*-${tag_name_suffix}$)
    before_tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'exo' | grep -P .*-${before_tag_name_suffix}$)
  fi
  if [ -z "$tag_name" ] || [ -z "$before_tag_name" ]; then
    popd &>/dev/null
    continue
  fi
  echo "*** $item $before_tag_name -> $tag_name"
  commitDepth=$(git log --grep '\[exo-release\]' $tag_name~$MAX_RELEASE_COMMITS_FETCH_DEPTH..$tag_name --oneline | wc -l)
  beforeCommitDepth=$(git log --grep '\[exo-release\]' $before_tag_name~$MAX_RELEASE_COMMITS_FETCH_DEPTH..$before_tag_name --oneline | wc -l)
  commitIds=$(git log --no-merges --pretty=format:"%H" $before_tag_name~$beforeCommitDepth...$tag_name~$commitDepth --first-parent -n ${MAX_COMMITS_LISTING_PER_MODULE} | xargs)
  commitstats=$(git log --no-merges --numstat --pretty="%H" $before_tag_name~$beforeCommitDepth...$tag_name~$commitDepth --first-parent -n ${MAX_COMMITS_LISTING_PER_MODULE} | awk 'NF==3 {plus+=$1; minus+=$2} END {printf("+%d, -%d\n", plus, minus)}')
  subbody=""
  modulelink="https://github.com/$org/$item"
  [ $item == "platform-private-distributions" ] && plf_range="of $before_tag_name -> $tag_name"
  [ -z "$commitIds" ] || echo "*** $item $before_tag_name -> $tag_name" >>$changelogfile
  for commitId in $commitIds; do
    message=$(git show --pretty=format:%s -s $commitId | sed -E 's/\(#[0-9]+\)//g' | xargs -0)
    echo $message | grep -q "Prepare Release" && continue
    echo $message | grep -q "continuous-release-template" && continue
    echo $message | grep -q "exo-release" && continue
    echo $message | grep -q "parent-pom" && continue
    echo $message | grep -q "eXo Tasks notifications" && continue
    echo $message | grep -q "Specify base branch when merging PR for eXo Tasks notifications" && continue
    echo $message | grep -q "SWF:" && continue
    #echo $message | grep -q "Merge Translation" && continue
    author=$(git show --format="%an" -s $commitId | xargs)
    commitLink="$modulelink/commit/$(git rev-parse $commitId)"
    fomattedCommitId=$(echo $commitId | head -c 7)
    echo "$commitLink $message *** $author"
    echo "	($fomattedCommitId) $message --- $author" >>$changelogfile
  done
  set -e
  popd &>/dev/null
done
[ -z "$(echo $body | xargs)" ] && echo "-- No changelog for this release." >>$changelogfile
echo "" >>$changelogfile
echo "===" >>$changelogfile
uploadlink="${STORAGE_URL}/$(echo ${plfVersion} | grep -oP ^[0-9]\.[0-9])/${plfVersion}/"
# Sanitize pwd
downloadlink="$(echo ${uploadlink}$(basename $changelogfile) | sed 's|private/|public/|g' | sed -E 's|//\w+:\w+@|//|')"
echo "Download link: $downloadlink"
wget -S --spider $downloadlink &>/dev/null
curl -T ${changelogfile} ${uploadlink}