#!/bin/bash -eu
# Args:
# Generate changelog of CI/CD as Builders Space Activity


declare -A buildersGithbIds=( [exo-swf]=NA )
declare -A githubScore=( [exo-swf]=0 )

getCommitAuthorFromGithub() {
  local _id="$1"
  echo $(curl --fail -XGET -H "Authorization: token ${GIT_TOKEN}" \
    -H 'Accept: application/vnd.github.luke-cage-preview+json' \
    -L "https://api.github.com/search/issues?q=${_id}" 2>/dev/null | jq .items[0].user.login | tr -d '"' 2>/dev/null || echo $_id)
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
    commitIds=$(git log --no-merges --pretty=format:"%H" $before_tag_name~2...$tag_name~2 | xargs)
    commitstats=$(git log --no-merges --numstat --pretty="%H" $before_tag_name~2...$tag_name~2 | awk 'NF==3 {plus+=$1; minus+=$2} END {printf("+%d, -%d\n", plus, minus)}')
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
        _githubusername=$(getCommitAuthorFromGithub $commitId)
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
             [ -z "${authorFullName}" ] || authorLink=$(echo "<a target=\"_self\" rel=\"noopener\" href=\"https://builders.meeds.io/portal/dw/profile/${authorBuildersID}\" class=\"user-suggester\">${authorFullName}</a>")
             [ -z "${authorFullName}" ] || setStat $authorBuildersID $userStat
           fi
        fi
        commitLink="$modulelink/commit/$(git rev-parse $commitId)"
        fomattedCommitId=$(echo $commitId | head -c 7)
        buildersTasks=$(echo  $message | grep -oPi '(BUILDER|MEED)(S)?-[0-9]+' | sort -u | xargs)
        eXoTasks=$(echo  $message | grep -oPi '(TASK|MAINT|EXO)-[0-9]+' | sort -u | xargs)
        transormedMessage="$message"
        for buildersTask in $buildersTasks; do 
          buildersTaskID=$(echo $buildersTask | sed -E 's/(BUILDER|MEED)(S)?-//gi')
          transormedMessage=$(echo $transormedMessage | sed "s|$buildersTask|<a href=\"https://builders.meeds.io/portal/meeds/tasks/taskDetail/$buildersTaskID\">$buildersTask</a>|g")
        done
        for eXoTask in $eXoTasks; do 
          eXoTaskID=$(echo $eXoTask | sed -E 's/(TASK|MAINT|EXO)-//gi')
          transormedMessage=$(echo $transormedMessage | sed "s|$eXoTask|<a href=\"https://community.exoplatform.com/portal/dw/tasks/taskDetail/$eXoTaskID\">$eXoTask</a>|g")
        done
        elt=$(echo "<li>(<a href=\"$commitLink\">$fomattedCommitId</a>) $transormedMessage <b>$authorLink</b></li>\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
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
[ -z "$(echo $body | xargs)" ] && body="<p>The changelog $plf_range is empty now, but awesome things are coming... stay tuned :)</p>" || body="<ul>\n\t$body</ul>"
#yearnotif=$(echo "<br/><br/>This is the <b>latest changelog</b> of $(date +%Y)! See you next year! 🎊 🎊 🥳 🥳\n\t" | gawk '{ gsub(/"/,"\\\"") } 1')
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