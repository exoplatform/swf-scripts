#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD as Tribe Space Activity

# 2 max commit after released dev commit (generated commits swf release)
MAX_RELEASE_COMMITS_FETCH_DEPTH=2
MAX_COMMITS_LISTING_PER_MODULE=15
MAX_REV_LIST_DEPTH=200

githubMeedsIssues=""

declare -A tribeGithbIds=( [exo-swf]=NA )
declare -A githubScore=( [exo-swf]=0 )
declare -A fileExtensionsMapping=([java]=java [jsp]=java [gtmpl]=groovy [groovy]=groovy [vue]=vuejs [js]=javascript [css]=css3 [less]=less [sh]=bash [feature]=selenium)
declare -A fontAwesomeMapping=([java]=java [vuejs]=vuejs [javascript]=js [css3]=css3 [less]=less [bash]=terminal [selenium]=vial)

function hasArrayValue() {
  local item="$1"
  shift 1
  local haystack="$@"
  echo "${haystack[@]}" | tr " " "\n" | grep -qP "^${item}\$"
}

function addGithubIssue() {
  local item=$1
  shift 1
  local tmpArray="$@"
  hasArrayValue $item ${tmpArray[@]} || tmpArray="${tmpArray} $item"
  echo ${tmpArray} | awk 'BEGIN{RS=" ";} {print $1}' | sort | uniq
}

getCommitProgrammingLanguages() {
  commitID=${1:-HEAD}
  fileExtensions=$(git diff-tree --no-commit-id --name-only -r $commitID | xargs -L 1 basename | grep '.' | cut -d '.' -f2 | uniq | xargs)
  [ -z "${fileExtensions}" ] && return
  languages=""
  for fileExt in ${fileExtensions}; do
    [ -z "${languages}" ] && languages=${fileExtensionsMapping[$fileExt]:-} || languages="${languages} ${fileExtensionsMapping[$fileExt]:-}"
  done
  echo ${languages}
}

getCommitLangURLs() {
  langs=$(getCommitProgrammingLanguages $1 | xargs -n1 | sort -u | xargs)
  languagesURLs=""
  for lang in $langs; do
    fontawesomeItem=${fontAwesomeMapping[$lang]} 
    langHTML="<i aria-hidden=\"true\" class=\"v-icon notranslate fab fa-${fontawesomeItem} theme--light\" style=\"font-size: 16px;\" title=\"${lang^}\"></i>"
    [ -z "${languagesURLs}" ] && languagesURLs="$langHTML" || languagesURLs="${languagesURLs} $langHTML"
  done
  echo $languagesURLs
}

isSameCommit() {
  [ "$(git rev-parse $1)" = "$(git rev-parse $2)" ]
}

findSourceCommit() {
  local ref="develop"
  if ! git show-ref --quiet refs/heads/$ref; then
    ref=$(git remote show origin | grep 'HEAD branch' | cut -d' ' -f5)
  fi
  local TARGET_COMMIT_PATCHID=$(
    git show --patch-with-raw "$1" |
      git patch-id |
      cut -d' ' -f1
  )

  local MATCHING_COMMIT_SHA=""
  for c in $(git rev-list origin/$ref -n ${MAX_REV_LIST_DEPTH}); do
    if [[ $(git show --patch-with-raw "$c" | git patch-id | cut -d' ' -f1) == "${TARGET_COMMIT_PATCHID}" ]]; then
      MATCHING_COMMIT_SHA=$c
      break
    fi
  done
  echo "$MATCHING_COMMIT_SHA"
}

getCommitMetadataFromGithub() {
  local _id="$1"
  local _repo="$2"
  gh api -H 'Accept: application/vnd.github.luke-cage-preview+json' "/repos/${_repo}/commits/${_id}" 2>/dev/null
}

getCommitAuthorFromMetadata() {
  echo $(echo "$1" | jq .author.login | xargs -r echo)
}

isCommitVerified() {
  local status=$(echo "$1" | jq .commit.verification.verified | xargs -r echo || echo "false")
  [ "${status}" = "true" ]
}

isCommitVerifiedByGithub() {
  echo "$1" | jq .commit.verification.payload | grep -q 'committer GitHub <noreply@github.com>'
}

isCommitSignedByexoswf() {
  local authorEmail=$(echo "$1" | jq .commit.author.email | xargs -r echo )
  local committerEmail=$(echo "$1" | jq .commit.committer.email | xargs -r echo )
  echo "$1" | jq .commit.verification.payload | grep -q '<exo-swf@exoplatform.com>' && [ "${authorEmail}" != "${committerEmail}" ]
}

getUserMetadataFromGithub() {
  local _id="$1"
  gh api -H 'Accept: application/vnd.github.luke-cage-preview+json' "/users/${_id}" 2>/dev/null
}

getIssueMetadataFromGithub() {
  local _repo="$1"
  local _id="$2"
  gh api -H 'Accept: application/vnd.github.luke-cage-preview+json' "/repos/${_repo}/issues/${_id}" 2>/dev/null
}

getIssueURLFromMetadata() {
  echo $(echo "$1" | jq .html_url | xargs -r echo)
}

getIssueTitleFromMetadata() {
  echo $(echo "$1" | jq .title | xargs -r echo)
}

getIssueStateFromMetadata() {
  echo $(echo "$1" | jq .state | xargs -r echo)
}

getIssueStateReasonFromMetadata() {
  echo $(echo "$1" | jq .state_reason | xargs -r echo)
}

getUserFullNameFromMetadata() {
  echo $(echo "$1" | jq .name | xargs -r echo)
}

getUserAvatarURLFromMetadata() {
  local _id="$1"
  echo $(echo "$1" | jq .avatar_url | xargs -r echo)
}

getTribeAuthorFromGithb() {
  curl --fail -XGET --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/gamification/connectors/github/hooksmanagement/users/$1" 2>/dev/null || echo "NA"
}

checkElementExists() {
  [ ! -z "${tribeGithbIds[$1]:-}" ]
}

setElementtoIds() {
  tribeGithbIds[$1]="$2"
}

getElementfromIds() {
  echo ${tribeGithbIds[$1]} 2>/dev/null || echo "NA"
}

getTribeProfile() {
  curl --fail -XGET --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/v1/social/users/$1" 2>/dev/null || echo ""
}

setStat() {
  [ -z "${githubScore[$1]:-}" ] && githubScore[$1]=$2 || ((githubScore[$1]+=$2))
}

getWinner() {
  local max=-1
  local winner=""
  for key in "${!githubScore[@]}"; do
    item=${githubScore[$key]}
    ((item > max)) && max=$item && winner=$key
  done
  echo $winner
}

modules=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-release-manager-catalog/contents/exo-platform/continuous-release-template-exo.json")

body=""
plf_range=""
grafana_dashboard="https://mon.exoplatform.org/d/g5gmgcpnz/deployed-exo-version"
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
    unset authorTribeID
    unset authorProfile
    unset authorFullName
    message=$(git show --pretty=format:%s -s $commitId | sed -E 's/\(#[0-9]+\)//g' | xargs -0)
    echo $message | grep -q "Prepare Release" && continue
    echo $message | grep -q "continuous-release-template" && continue
    echo $message | grep -q "exo-release" && continue
    echo $message | grep -q "parent-pom" && continue
    echo $message | grep -q "eXo Tasks notifications" && continue
    echo $message | grep -q "Specify base branch when merging PR for eXo Tasks notifications" && continue
    echo $message | grep -q "SWF:" && continue
    #echo $message | grep -q "Merge Translation" && continue
    git config diff.renames 0
    author=$(git show --format="%an" -s $commitId | xargs)
    userStat=$(git show --numstat --pretty="%H" $commitId | awk 'NF==3 {score+=$1+$2} END {printf("+%d\n", score)}')
    git config diff.renames 0
    commitMetadata=$(getCommitMetadataFromGithub $commitId $org/$item)
    _githubusername=$(getCommitAuthorFromMetadata "${commitMetadata}")
    authorLink="${author}"
    if [ ! -z "${_githubusername}" ]; then
      if checkElementExists ${_githubusername}; then
        authorTribeID="$(getElementfromIds ${_githubusername})"
      else
        authorTribeID="$(getTribeAuthorFromGithb ${_githubusername})"
        setElementtoIds ${_githubusername} $authorTribeID
      fi
      authorProfile=$(getTribeProfile $authorTribeID)
      if [ ! -z "${authorProfile}" ]; then
        authorFullName="$(echo ${authorProfile} | jq .fullname | tr -d '\"' || echo "")"
        [ -z "${authorFullName}" ] || authorLink=$(echo "<a target=\"_self\" rel=\"noopener\" href=\"https://community.exoplatform.com/portal/dw/profile/${authorTribeID}\" class=\"user-suggester\">${authorFullName}</a>")
        [ -z "${authorFullName}" ] || setStat $authorTribeID $userStat
      fi
    fi
    commitLink="$modulelink/commit/$(git rev-parse $commitId)"
    fomattedCommitId=$(echo $commitId | head -c 7)
    buildersTasks=$(echo $message | grep -oPi '(BUILDER|MEED)(S)?-[0-9]+' | sort -u | xargs)
    eXoTasks=$(echo $message | grep -oPi '(TASK|MAINT|EXO)-[0-9]+' | sort -u | xargs)
    githubIssues=$(echo $message | grep -oPi 'Meeds-io/meeds#[0-9]+' | sort -u | xargs)
    githubMIPSIssues=$(echo $message | grep -oPi 'Meeds-io/M[IP]{2}s#[0-9]+' | sort -u | xargs)
    transormedMessage="$message"
    featureHtml="<i aria-hidden=\"true\" class=\"v-icon notranslate fas fa-rocket theme--light\" style=\"font-size: 16px;\" title=\"Feature\"></i>"
    bugHtml="<i aria-hidden=\"true\" class=\"v-icon notranslate fas fa-bug theme--light\" style=\"font-size: 16px;\" title=\"Bug\"></i>"
    i18nHtml="<i aria-hidden=\"true\" class=\"v-icon notranslate fas fa-flag theme--light\" style=\"font-size: 16px;\" title=\"i18n\"></i>"
    transormedMessage=$(echo $transormedMessage | sed -e "s|feat:|${featureHtml}|gi" -e "s|fix:|${bugHtml}|gi" -e "s|Merge Translations|${i18nHtml} Merge Translations|g")
    for buildersTask in $buildersTasks; do
      buildersTaskID=$(echo $buildersTask | sed -E 's/(BUILDER|MEED)(S)?-//gi')
      transormedMessage=$(echo $transormedMessage | sed "s|$buildersTask|<a href=\"https://builders.meeds.io/portal/meeds/tasks/taskDetail/$buildersTaskID\">$buildersTask</a>|g")
    done
    for eXoTask in $eXoTasks; do
      eXoTaskID=$(echo $eXoTask | sed -E 's/(TASK|MAINT|EXO)-//gi')
      transormedMessage=$(echo $transormedMessage | sed "s|$eXoTask|<a href=\"https://community.exoplatform.com/portal/dw/tasks/taskDetail/$eXoTaskID\">$eXoTask</a>|g")
    done
    for githubIssue in $githubIssues; do
      githubIssueID=$(echo $githubIssue | sed 's|Meeds-io/meeds#||gi')
      transormedMessage=$(echo $transormedMessage | sed "s|$githubIssue|<a href=\"https://github.com/Meeds-io/meeds/issues/$githubIssueID\">$githubIssue</a>|g")
      githubMeedsIssues=$(addGithubIssue "meeds-${githubIssueID}" ${githubMeedsIssues})
    done
    for githubMIPSIssue in $githubMIPSIssues; do
      githubMIPSIssueID=$(echo $githubMIPSIssue | sed -e 's|Meeds-io/MIPs#||gi' -e 's|Meeds-io/MPIs#||gi')
      transormedMessage=$(echo $transormedMessage | sed "s|$githubMIPSIssue|<a href=\"https://github.com/Meeds-io/MIPs/issues/$githubMIPSIssueID\">$githubMIPSIssue</a>|g")
      githubMeedsIssues=$(addGithubIssue "mips-${githubMIPSIssueID}" ${githubMeedsIssues})
    done
    sourceCommitID=$(findSourceCommit $commitId)
    verificationCheck=""
    if isCommitVerified "${commitMetadata}"; then
      if isCommitVerifiedByGithub "${commitMetadata}"; then
        verificationCheck="<i aria-hidden=\"true\" class=\"v-icon notranslate far fa-check-circle theme--light\" style=\"font-size: 16px;\" title=\"Verified commit (Signed by Github)\"></i>"
      elif isCommitSignedByexoswf "${commitMetadata}"; then
        verificationCheck="<i aria-hidden=\"true\" class=\"v-icon notranslate far fa-check-circle theme--light\" style=\"font-size: 16px;\" title=\"Verified commit (Signed by exo-swf)\"></i>"
      else
        verificationCheck="<i aria-hidden=\"true\" class=\"v-icon notranslate fa fa-check-circle theme--light\" style=\"font-size: 16px;\" title=\"Verified commit (Self Signed)\"></i>"
      fi
    fi
    commitsLangURLs=$(getCommitLangURLs $commitId)
    if [ ! -z "${sourceCommitID}" ] && ! isSameCommit $sourceCommitID $commitId; then
      sourceCommitLink="$modulelink/commit/$(git rev-parse $sourceCommitID)"
      cherrypickHtml="<i aria-hidden=\"true\" class=\"v-icon notranslate fab fa-sourcetree theme--light\" style=\"font-size: 16px;\"></i>"
      elt=$(echo "<li>(<a href=\"$commitLink\">$fomattedCommitId</a>)<a href=\"$sourceCommitLink\" title=\"Source commit\">${cherrypickHtml}</a> $transormedMessage <b>$authorLink</b> $commitsLangURLs $verificationCheck</li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
    else
      elt=$(echo "<li>(<a href=\"$commitLink\">$fomattedCommitId</a>) $transormedMessage <b>$authorLink</b> $commitsLangURLs $verificationCheck</li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
    fi
    echo "$commitLink $message *** $author -- $authorTribeID"
    echo "	($fomattedCommitId) $message --- $author" >>$changelogfile
    subbody="$subbody$elt"
  done
  beforeTagCommitID=$(git rev-parse --short $before_tag_name~2)
  tagCommitID=$(git rev-parse --short $tag_name~2)
  fullchangeloglink=$(echo "<a href=\"https://github.com/${org}/${item}/compare/${beforeTagCommitID}...${tagCommitID}\">$before_tag_name..$tag_name</a>" | gawk '{ gsub(/"/,"\\\"") } 1')
  [ -z "$subbody" ] || body="$body<li><b>$item</b> ${fullchangeloglink} (${commitstats}):\n\t<ul>\n\t$subbody</ul>\n\t</li>\n\t"
  set -e
  popd &>/dev/null
done
[ -z "$(echo $body | xargs)" ] && echo "-- No changelog for this release." >>$changelogfile
echo "" >>$changelogfile
echo "===" >>$changelogfile
bodyStatus="$body"
[ -z "$(echo $body | xargs)" ] && body="<p>The changelog $plf_range is empty now, but awesome things are coming... stay tuned :)</p>" || body="<p>Release changes:</p>\n\n<ul>\n\t$body</ul>"
dep_status=$(echo "Deployment status: \n\t\n\t<a href=\"$grafana_dashboard\">Grafana Dashboard</a>.\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
#yearnotif=$(echo "<br/><br/>This is the <b>latest changelog</b> of $(date +%Y)! See you next year! 🎊 🎊 🥳 🥳\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
if [ ! -z "${githubMeedsIssues}" ]; then
  listitemsCount=0
  githubIssuesblock="<p>Github Issues:</p>\n\n<ul>\n\n"
  githubIssueItems=""
  for githubMeedsIssue in ${githubMeedsIssues}; do
    [[ ${githubMeedsIssue} =~ ^mips ]] && issueRepo="Meeds-io/Mips" || issueRepo="Meeds-io/meeds" 
    githubMeedsIssueNumber=$(echo $githubMeedsIssue | grep -oP '[0-9]+$')
    githubIssueMetadata=$(getIssueMetadataFromGithub $issueRepo $githubMeedsIssueNumber)
    githubIssueLink=$(getIssueURLFromMetadata "${githubIssueMetadata}")
    githubIssueLinkText=$(echo ${githubMeedsIssue^} | sed -e 's/-/#/g' -e 's/mips/MIPs/gi')
    githubIssueTitle=$(getIssueTitleFromMetadata "${githubIssueMetadata}")
    githubIssueState=$(getIssueStateFromMetadata "${githubIssueMetadata}")
    stateEmoji="<i aria-hidden=\"true\" class=\"v-icon notranslate fa fa-door-open theme--light\" style=\"font-size: 16px;\" title=\"Open\"></i>"
    if [ ${githubIssueState} = "closed" ]; then
      stateReason=$(getIssueStateReasonFromMetadata "${githubIssueMetadata}")
      if [ "${stateReason}" = "completed" ]; then 
        stateEmoji="<i aria-hidden=\"true\" class=\"v-icon notranslate fa fa-check theme--light\" style=\"font-size: 16px;\" title=\"Completed\"></i>"
      else 
        stateEmoji="<i aria-hidden=\"true\" class=\"v-icon notranslate fa fa-door-closed theme--light\" style=\"font-size: 16px;\" title=\"Closed\"></i>"
      fi
    fi
    elt=$(echo "<li><b><a href=\"$githubIssueLink\">${githubIssueLinkText}</a>:</b> $githubIssueTitle ${stateEmoji}</li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
    listitemsCount=$((listitemsCount + 1))
    githubIssueItems="${githubIssueItems}\n${elt}"
  done
  githubIssuesblock="${githubIssuesblock}${githubIssueItems}</ul>"
  [ "$listitemsCount" -gt "0" ] && body="$body$githubIssuesblock"
fi
if [ ! -z "$(echo $bodyStatus | xargs)" ]; then
  listitemsCount=0
  contributors="<p>Github Contributors:</p>\n\n"
  for githubUser in ${!tribeGithbIds[@]}; do
    [ "${githubUser}" = "exo-swf" ] && continue
    [ -z "${githubScore[${tribeGithbIds[$githubUser]:-}]:-}" ] && continue
    githubUserMetadata=$(getUserMetadataFromGithub $githubUser)
    githubFullName=$(getUserFullNameFromMetadata "${githubUserMetadata}")
    [ "${githubFullName,,}" = "null" ] && githubFullName=$githubUser
    githubAvatarURL=$(getUserAvatarURLFromMetadata "${githubUserMetadata}")
    githubURL="https://github.com/${githubUser}"
    score=$((${githubScore[${tribeGithbIds[$githubUser]}]}))
    contrib=$(echo "<ol style=\"display: inline-block;text-align: center;list-style-type: none;\"><a href=\"${githubURL}\"><img src=\"${githubAvatarURL}\" title=\"${githubFullName}\" style=\"height:30px;border-radius: 50%;\"></a><br/><span>${score} pts</span></ol>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
    contributors=${contributors}${contrib}
    listitemsCount=$((listitemsCount + 1))
  done
  [ "$listitemsCount" -gt "0" ] && body="$body$contributors<br/>"
fi
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
activityIds=""
for SPACE_ID in ${SPACES_IDS/,/ }; do
  activityId=$(curl --fail --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/v1/social/spaces/${SPACE_ID}/activities" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"<p>${changeloghash} ${cicdhash} generated $(date).</p>\n\n$body\n\",\"type\":\"\",\"templateParams\":{},\"files\":[]}" 2>/dev/null | jq .id 2>/dev/null | tr -d '"' || echo "")
  activityIds="${activityId} ${activityIds}"
done
winner=$(getWinner)
if [ ! -z "${activityId}" ] && [ ! -z "${winner}" ]; then
  congratulationsMsg="Congratulations, you are the winner of ${plfVersion}'s changelog! Keep it up !🎖🎖🎖"
  winnerScore=$((${githubScore[$winner]}))
  if [ "${winnerScore:-0}" -gt "999" ]; then
    congratulationsMsg="Warmest congratulations on your achievement! Wishing you even more success in the future! 🏆🥇"
  fi
  echo "Generating Kudos on activity #${activityId}... Winner is ${winner}."
  curl --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/kudos/api/kudos" \
    -H 'Content-Type: application/json' \
    --data "{\"entityType\":\"ACTIVITY\",\"entityId\":\"${activityId}\",\"parentEntityId\":\"\",\"receiverType\":\"user\",\"receiverId\":\"${winner}\",\"message\":\"<div>${congratulationsMsg}</div>\n\"}"
fi
