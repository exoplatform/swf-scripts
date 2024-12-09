#!/bin/bash -eu

### Colors
info() {
    echo -e "\033[1;34m[Info]\033[0m $1"
}

error() {
    echo -e "\033[1;31m[Error]\033[0m $1"
}

success() {
    echo -e "\033[1;32m[Success]\033[0m $1"
}

warn() {
    echo -e "\033[1;33m[Warning]\033[0m $1"
}

action() {
    echo -e "\033[1;36m[Action]:\033[0m $1"
}

# Function to colorize status
colorize_status() {
    case $1 in
        ahead)
            echo -e "\033[1;32m$1\033[0m"  # Green
            ;;
        behind|identical)
            echo -e "\033[1;33m$1\033[0m"  # Yellow
            ;;
        diverged)
            echo -e "\033[1;31m$1\033[0m"  # Red
            ;;
        unknown)
            echo -e "\033[1;35m$1\033[0m"  # Magenta
            ;;
        *)
            echo "$1"  # Default (no color)
            ;;
    esac
}

# Strip color codes for accurate length calculation
strip_color_codes() {
    echo "$1" | sed -e 's/\033\[[0-9;]*m//g'
}


### Functions for Jenkins Job Management
getJenkinsQueuedJobId() {
    curl -fsSL "https://${JENKINS_HOST}/queue/api/json?tree=items%5Bid%2Ctask%5Bname%5D%5D" | jq -r ".items[] | select(.task.name | contains( \"${1}\")) | .id"
}

cancelJenkinsQueuedJobId() {
    curl -fsSL -XPOST "https://${JENKINS_HOST}/queue/cancelItem?id=${1}" 
}

cancelJenkinsQueuedJobName() {
    jobSubname="${1}"
    sleep 15  # Wait for GitHub push webhook
    jobQueueId=$(getJenkinsQueuedJobId ${jobSubname})
    
    if [ -z "${jobQueueId}" ]; then 
        warn "Could not find the queue ID of ${jobSubname} to be canceled!"
    else
        cancelJenkinsQueuedJobId ${jobQueueId}
    fi
}

### Main Script
# Ensure FB_NAME is set
[ -z "${FB_NAME}" ] && exit 1

set +u
# Default REBASE_PRS value
[ -z "${REBASE_PRS:-}" ] && REBASE_PRS=false

# Jenkins Host not set warning
if [ -z "${JENKINS_HOST:-}" ]; then 
    warn "Secret JENKINS_HOST is not specified! Jenkins Jobs queue cleanup won't be performed!"
fi

set -u

info "Parsing FB ${FB_NAME} Seed Job Configuration..."
export FILTER_BRANCH_SQUELCH_WARNING=1  # Filter-branch hide warnings
current_date=$(date '+%s')

action "Parsing FB repositories from catalog..."
fblist=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_$(echo ${FB_NAME//-} | tr '[:upper:]' '[:lower:]').groovy" | grep "project:")

# Include company modules if enabled
if ${COMPANY_MODULES_ENABLED:-false}; then 
    set +e
    cmpfblist=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/company/seed_jobs_ci.groovy" | grep "feature/${FB_NAME}" | grep "project:")
    set -e
    [ -z "${cmpfblist:-}" ] || fblist=$(echo -e "${fblist}\n${cmpfblist}")
fi

modules_length=$(echo $fblist | grep -o 'project:' | wc -w)
info "Modules count: ${modules_length}"

counter=0
action "Done. Scanning unrebased modules..."
modulesToRebase=""
# Define column widths
counter_width=${#modules_length}
repo_width=45  # Width for the combined org/item column
branch_width=30
status_width=12
ahead_behind_width=20
# Iterate over each module and check rebase status
while IFS=']' read -r line; do
    counter=$((counter+1))  
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)
    
    # Skip empty values
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && continue

    # Determine base branch for rebase
    if [ -z "${BASE_BRANCH:-}" ]; then 
        if [ "${org,,}" = "meeds-io" ] && [[ ! $item =~ ^deeds ]]; then
            baseBranch=develop-exo
        else 
            baseBranch=develop
        fi
    elif [[ $item =~ ^deeds-tenant$ ]]; then 
        baseBranch="${BASE_BRANCH}"
    elif [[ $item =~ ^deeds ]]; then 
        baseBranch=develop
    else
        baseBranch="${BASE_BRANCH}"
    fi
    
    [ "${org,,}" = "meeds-io" ] || baseBranch="develop"
        
    # Check the comparison status between branches
    compareJson=$(gh api /repos/${org}/${item}/compare/${baseBranch}...feature/${FB_NAME})
    status=$(echo "$compareJson" | jq -r .status)
    aheadby=$(echo "$compareJson" | jq -r .ahead_by)
    behindby=$(echo "$compareJson" | jq -r .behind_by)
    if [ "${behindby}" -eq "0" ]; then 
      behindbyMsg="\033[1;32m${behindby}\033[0m"
    else 
      behindbyMsg="\033[1;31m${behindby}\033[0m"
    fi
    aheadbyMsg="\033[1;34m$aheadby\033[0m"
    formatted_counter=$(printf "%0${counter_width}d" $counter)

    # Calculate status color length without codes
    colored_status=$(colorize_status "$status")
    status_length=$(strip_color_codes "$colored_status")
    status_width=$((status_width > ${#status_length} ? status_width : ${#status_length}))

    # Format the fields for tabular display
    printf "\033[1;34m[Info]\033[0m %-*s %-*s %-*s %-*s %-*s\n" \
        $((counter_width + 3)) "(${formatted_counter}/${modules_length})" \
        $repo_width "${org}/${item}" \
        $branch_width "${baseBranch}...feature/${FB_NAME}" \
        $status_width "${colored_status}" \
        $ahead_behind_width "Ahead: $(echo -e $aheadbyMsg), Behind: $(echo -e $behindbyMsg)"

    # If not diverged, no rebase is needed
    if [ "${status:-}" != "diverged" ]; then
        continue
    fi

    modulesToRebase="${modulesToRebase} ${org}@${item}@${baseBranch}"
done <<< "$fblist"
modulesToRebase="$(echo $modulesToRebase | xargs)"
if [ -z "${modulesToRebase}" ]; then 
  success "All repositories are rebased! Nothing to do!"
  exit 0
fi

action "Starting rebase repositories..."

# Rebase each module in the list
rebasesCounter=0
for moduleToRebase in ${modulesToRebase}; do
    rebasesCounter=$((rebasesCounter+1))  
    org=$(echo $moduleToRebase | cut -d '@' -f1)
    item=$(echo $moduleToRebase | cut -d '@' -f2 )
    baseBranch=$(echo $moduleToRebase | cut -d '@' -f3)
    action "Rebasing branch feature/${FB_NAME} on ${baseBranch} of repository ${org}/${item}..."
    # Clone repository and rebase feature branch
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
    git checkout feature/${FB_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)

    # Attempt rebase with recursive strategy, fallback to 'ours' if it fails
    if ! git -c advice.skippedCherryPicks=false rebase origin/${baseBranch} feature/${FB_NAME} >/dev/null; then
        info "Rebasing with recursive strategy has failed!"
        action "Trying 'ours' rebase strategy..."
        git rebase --abort || :
        
        if ! git -c advice.skippedCherryPicks=false rebase origin/${baseBranch} feature/${FB_NAME} --strategy-option ours >/dev/null || [ ! -z "$(git diff -w origin/feature/${FB_NAME})" ]; then 
            error "Could not rebase feature/${FB_NAME} for ${org}/${item}!"
            exit 1
        fi
    fi

    # Log changes before and after the rebase
    git log --oneline --cherry origin/${baseBranch}..HEAD
    if [ ! -z "$(git diff origin/feature/${FB_NAME} 2>/dev/null)" ]; then
        info "Changes before the rebase:"
        echo -e "\033[1;32m****\033[0m"
        git log HEAD..origin/feature/${FB_NAME} --oneline --pretty=format:"(%C(yellow)%h%Creset) %s"
        echo -e "\033[1;32m****\033[0m"
    else 
        info "No changes detected!"  
    fi

    new_head=$(git rev-parse --short HEAD)
    
    # If the HEAD has changed, push and handle Jenkins job cancellation if needed
    if [ "${prev_head}" != "${new_head}" ]; then
        info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
        git push origin feature/${FB_NAME} --force-with-lease 2>&1 | grep -v remote ||:
        
        # Cancel Jenkins job if required
        if [ ! -z "${JENKINS_HOST:-}" ] && [ "${rebasesCounter}" -gt "1" ]; then 
            cancelJenkinsQueuedJobName "${item}-${FB_NAME}-fb-ci" &  # Async call
        fi

        # Check for incorrect submodule versions
        wrongSubmodulesVersion=$(grep -Pirl '<version>.*\.x(-exo|-meed)?-SNAPSHOT</version>' --include=pom.xml | xargs)
        if [ ! -z ${wrongSubmodulesVersion} ]; then
            warn "Unfixed ${FB_NAME} FB Maven submodules version detected!"
            grep -Pirn '<version>.*\.x(-exo|-meed)?-SNAPSHOT</version>' --include=pom.xml | sed -E 's/^/ - /g'
        fi

        # Handle PR rebases if REBASE_PRS is true
        if ${REBASE_PRS}; then 
            action "Looking for PRs with base feature/${FB_NAME}..."
            fbPRs=$(gh api /repos/${org}/${item}/pulls?base=feature/${FB_NAME})
            
            for fbPR in $(echo "${fbPRs}" | jq -r '.[] | @base64'); do
                _jq() {
                    echo ${fbPR} | base64 --decode | jq -r ${1}
                }
                prBranch=$(_jq '.head.ref')
                prNumber=$(_jq '.number')
                action "Trying to rebase PR https://github.com/${org}/${item}/pull/${prNumber} branch: ${prBranch}..."
                
                # Rebase PR branch
                git checkout -f ${prBranch} &>/dev/null
                prev_head=$(git rev-parse --short HEAD)
                
                if ! git rebase feature/${FB_NAME} ${prBranch} >/dev/null; then 
                    error "Cannot rebase ${prBranch} on feature/${FB_NAME} for ${org}/${item}! Skipped!"
                    git rebase --abort &>/dev/null || :
                else
                    new_head=$(git rev-parse --short HEAD)
                    info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
                    git push origin ${prBranch}:${prBranch} --force-with-lease 2>&1 | grep -v remote ||:
                fi
            done
            info "PRs rebase finished."
        fi
    fi

    popd &>/dev/null
done

# Wait for asynchronous jobs to complete
wait < <(jobs -p)

echo "================================================================================================="
success "Rebase done (${rebasesCounter} rebases)!"
