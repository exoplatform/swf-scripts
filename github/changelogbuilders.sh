#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD as Builders Space Activity

# 2 max commit after released dev commit (generated commits swf release)
MAX_RELEASE_COMMITS_FETCH_DEPTH=2

declare -A buildersGithbIds=( [exo-swf]=NA )
declare -A githubScore=( [exo-swf]=-1000000000 )

isSameCommit() {
  [ "$(git rev-parse $1)" = "$(git rev-parse $2)" ]
}

findSourceCommit() {
  local ref="develop"
  local TARGET_COMMIT_PATCHID=$(
    git show --patch-with-raw "$1" |
	  git patch-id |
	  cut -d' ' -f1
  )

  local MATCHING_COMMIT_SHA=""
  for c in $(git rev-list origin/$ref ); do
	  if [[ $(git show --patch-with-raw "$c" | git patch-id | cut -d' ' -f1) == "${TARGET_COMMIT_PATCHID}" ]]; then 
      MATCHING_COMMIT_SHA=$c 
	    break; 
	  fi
  done
    echo "$MATCHING_COMMIT_SHA"
  }

getCommitAuthorFromGithub() {
  local _id="$1"
  local _repo="$2"
  echo $(curl --fail -XGET -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.luke-cage-preview+json' \
    -L "https://api.github.com/repos/${_repo}/commits/${_id}" 2>/dev/null | jq .author.login | tr -d '"' 2>/dev/null || echo "")
}

getUserFullNameFromGithub() {
  local _id="$1"
  echo $(curl --fail -XGET \
    -H 'Accept: application/vnd.github.luke-cage-preview+json' \
    -L "https://api.github.com/users/${_id}" 2>/dev/null | jq .name | tr -d '"' 2>/dev/null || echo "")
}

getUserAvatarURLFromGithub() {
  local _id="$1"
  echo $(curl --fail -XGET \
    -H 'Accept: application/vnd.github.luke-cage-preview+json' \
    -L "https://api.github.com/users/${_id}" 2>/dev/null | jq .avatar_url | tr -d '"' 2>/dev/null || echo "")
}

getBuildersAuthorFromGithb() {
  curl --fail -XGET --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/gamification/connectors/github/hooksmanagement/users/$1" 2>/dev/null || echo "NA"
}

checkElementExists() {
  [ ! -z "${buildersGithbIds[$1]:-}" ]
}

setElementtoIds() {
  buildersGithbIds[$1]="$2"
}

getElementfromIds() {
  echo ${buildersGithbIds[$1]} 2>/dev/null || echo "NA"
}

getBuildersProfile() {
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

modules=$(curl -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.v3.raw' \
    -L "https://api.github.com/repos/exoplatform/swf-release-manager-catalog/contents/meeds/continuous-release-template-meed.json")

body=""
plf_range=""
grafana_dashboard="https://mon.exoplatform.org/d/g5gmgcpnz/deployed-exo-version"
echo "Done. Performing action..."
git clone git@github.com:Meeds-io/meeds &>/dev/null
pushd meeds &>/dev/null
tag_name_suffix=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'meed' | grep -oP [0-9]{8}$ | tail -1)
before_tag_name_suffix=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'meed' | grep -oP [0-9]{8}$ | tail -2 | head -1)
plfVersion=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'meed' | grep -P .*-${tag_name_suffix}$ )
popd &>/dev/null
rm -rf meeds &>/dev/null
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
    tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'meed' | grep -P .*-${tag_name_suffix}$ )
    before_tag_name=$(git for-each-ref --sort=creatordate --format '%(refname)' refs/tags | sed 's|refs/tags/||g' | grep 'meed' | grep -P .*-${before_tag_name_suffix}$)
    if [ -z "$tag_name" ] || [ -z "$before_tag_name" ]; then
      popd &>/dev/null
      continue
    fi
    echo "*** $item $before_tag_name -> $tag_name"
    commitDepth=$(git log --grep '\[exo-release\]' $tag_name~$MAX_RELEASE_COMMITS_FETCH_DEPTH..$tag_name --oneline | wc -l)
    beforeCommitDepth=$(git log --grep '\[exo-release\]' $before_tag_name~$MAX_RELEASE_COMMITS_FETCH_DEPTH..$before_tag_name --oneline | wc -l)
    commitIds=$(git log --no-merges --pretty=format:"%H" $before_tag_name~$beforeCommitDepth...$tag_name~$commitDepth | xargs)
    commitstats=$(git log --no-merges --numstat --pretty="%H" $before_tag_name~$beforeCommitDepth...$tag_name~$commitDepth | awk 'NF==3 {plus+=$1; minus+=$2} END {printf("+%d, -%d\n", plus, minus)}')
    subbody=""
    modulelink="https://github.com/$org/$item"
    [ $item == "meeds" ] && plf_range="of $before_tag_name -> $tag_name"
    for commitId in $commitIds; do
        unset authorBuildersID
        unset authorProfile
        unset authorFullName
        message=$(git show --pretty=format:%s -s $commitId | sed -E 's/\(#[0-9]+\)//g' | xargs -0)
        echo $message | grep -q "Prepare Release" && continue
        echo $message | grep -q "continuous-release-template" && continue
        echo $message | grep -q "exo-release" && continue
        echo $message | grep -q "parent-pom" && continue
        echo $message | grep -q "eXo Tasks notifications" && continue
        echo $message | grep -q "Specify base branch when merging PR for eXo Tasks notifications" && continue
        #echo $message | grep -q "Merge Translation" && continue
        author=$(git show --format="%an" -s $commitId | xargs)
        userStat=$(git show --numstat --pretty="%H" $commitId | awk 'NF==3 {score+=$1+$2} END {printf("+%d\n", score)}')
        git config diff.renames 0
        _githubusername=$(getCommitAuthorFromGithub $commitId $org/$item)
        authorLink="${author}"
        if [ ! -z "${_githubusername}" ]; then 
           if checkElementExists ${_githubusername}; then 
              authorBuildersID="$(getElementfromIds ${_githubusername})"
           else 
              authorBuildersID="$(getBuildersAuthorFromGithb ${_githubusername})"
              setElementtoIds ${_githubusername} $authorBuildersID
           fi
           authorProfile=$(getBuildersProfile $authorBuildersID)
           if [ ! -z "${authorProfile}" ]; then 
             authorFullName="$(echo ${authorProfile} | jq .fullname | tr -d '\"' || echo "")"
             [ -z "${authorFullName}" ] || authorLink=$(echo "<a target=\"_self\" rel=\"noopener\" href=\"${SERVER_URL}/portal/meeds/profile/${authorBuildersID}\" class=\"user-suggester\">${authorFullName}</a>")
             [ -z "${authorFullName}" ] || setStat $authorBuildersID $userStat
           fi
        fi
        commitLink="$modulelink/commit/$(git rev-parse $commitId)"
        fomattedCommitId=$(echo $commitId | head -c 7)
        buildersTasks=$(echo  $message | grep -oPi '(BUILDER|MEED)(S)?-[0-9]+' | sort -u | xargs)
        eXoTasks=$(echo  $message | grep -oPi '(TASK|MAINT|EXO)-[0-9]+' | sort -u | xargs)
        githubIssues=$(echo  $message | grep -oPi 'Meeds-io/meeds#[0-9]+' | sort -u | xargs)
        githubMIPSIssues=$(echo  $message | grep -oPi 'Meeds-io/MIPs#[0-9]+' | sort -u | xargs)
        transormedMessage="$message"
        sparklesImg=$(echo "<img src=\"https://github.githubassets.com/images/icons/emoji/unicode/2728.png\" title=\"feature\" style=\"height:15px;\">\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        fixImg=$(echo "<img src=\"https://github.githubassets.com/images/icons/emoji/unicode/1f41b.png\" title=\"fix\" style=\"height:15px;\">\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        transormedMessage=$(echo $transormedMessage | sed -e "s|feat:|${sparklesImg}|gi" -e "s|fix:|${fixImg}|gi")
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
        done
        for githubMIPSIssue in $githubMIPSIssues; do 
          githubMIPSIssueID=$(echo $githubMIPSIssue | sed 's|Meeds-io/MIPs#||gi')
          transormedMessage=$(echo $transormedMessage | sed "s|$githubMIPSIssue|<a href=\"https://github.com/Meeds-io/MIPs/issues/$githubMIPSIssueID\">$githubMIPSIssue</a>|g")
        done
        sourceCommitID=$(findSourceCommit $commitId)
        if [ ! -z "${sourceCommitID}" ] && ! isSameCommit $sourceCommitID $commitId; then 
          sourceCommitLink="$modulelink/commit/$(git rev-parse $sourceCommitID)"
          elt=$(echo "<li>(<a href=\"$commitLink\">$fomattedCommitId</a>)[<a href=\"$sourceCommitLink\" title=\"Cherry-picked source commit\">CP</a>] $transormedMessage <b>$authorLink</b></li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        else
          elt=$(echo "<li>(<a href=\"$commitLink\">$fomattedCommitId</a>) $transormedMessage <b>$authorLink</b></li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
        fi
        echo "$commitLink $message *** $author -- $authorBuildersID"
        subbody="$subbody$elt"
    done
    beforeTagCommitID=$(git rev-parse --short $before_tag_name~2)
    tagCommitID=$(git rev-parse --short $tag_name~2)
    fullchangeloglink=$(echo "<a href=\"https://github.com/${org}/${item}/compare/${beforeTagCommitID}...${tagCommitID}\">$before_tag_name..$tag_name</a>" | gawk '{ gsub(/"/,"\\\"") } 1')
    [ -z "$subbody" ] || body="$body<li><b>$item</b> ${fullchangeloglink} (${commitstats}):\n\t<ul>\n\t$subbody</ul>\n\t</li>\n\t"
    set -e
    popd &>/dev/null
done
bodyStatus="$body"
[ -z "$(echo $body | xargs)" ] && body="<p>The changelog $plf_range is empty now, but awesome things are coming... stay tuned :)</p>" || body="<ul>\n\t$body</ul>"
dep_status=$(echo "Deployment status: \n\t\n\t<a href=\"$grafana_dashboard\">Grafana Dashboard</a>.\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
#yearnotif=$(echo "<br/><br/>This is the <b>latest changelog</b> of $(date +%Y)! See you next year! 🎊 🎊 🥳 🥳\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')

if [ ! -z "$(echo $bodyStatus | xargs)" ]; then
  listitemsCount=0
  contributors="<p>Github Contributors:</p>\n\n"
  for githubUser in ${!buildersGithbIds[@]}; do 
    [ "${githubUser}" = "exo-swf" ] && continue
    [ -z "${githubScore[${buildersGithbIds[$githubUser]:-}]:-}" ] && continue
    githubFullName=$(getUserFullNameFromGithub $githubUser)
    [ "${githubFullName,,}" = "null" ] && githubFullName=$githubUser
    githubAvatarURL=$(getUserAvatarURLFromGithub $githubUser)
    githubURL="https://github.com/${githubUser}"
    score=$((${githubScore[${buildersGithbIds[$githubUser]}]}))
    contrib=$(echo "<ol style=\"display: inline-block;text-align: center;list-style-type: none;\"><a href=\"${githubURL}\"><img src=\"${githubAvatarURL}\" title=\"${githubFullName}\" style=\"height:30px;border-radius: 50%;\"></a><br/><span>${score} pts</span></ol>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
    contributors=${contributors}${contrib}
    listitemsCount=$((listitemsCount+1))
  done
  [ "$listitemsCount" -gt "0" ] && body="$body$contributors<br/>"
fi
body=$body$dep_status #$yearnotif
changeloghash=$(echo '<a target="_blank" class="metadata-tag" rel="noopener" title="Start a search based on this tag">#Changelog</a>' | gawk '{ gsub(/"/,"\\\"") } 1')
cicdhash=$(echo '<a target="_blank" class="metadata-tag" rel="noopener" title="Start a search based on this tag">#cicd</a>' | gawk '{ gsub(/"/,"\\\"") } 1')
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
  echo "Generating Kudos on activity #${activityId}... Winner is ${winner}."
  curl --user "${USER_NAME}:${USER_PASSWORD}" "${SERVER_URL}/rest/private/kudos/api/kudos" \
    -H 'Content-Type: application/json' \
    --data "{\"entityType\":\"ACTIVITY\",\"entityId\":\"${activityId}\",\"parentEntityId\":\"\",\"receiverType\":\"user\",\"receiverId\":\"${winner}\",\"message\":\"<div>Congratulations, you are the winner of ${plfVersion}'s changelog! Keep it up !</div>\n\"}"
fi