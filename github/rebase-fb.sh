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
        

    modulesToRebase="${modulesToRebase} ${org}@${item}@${baseBranch}"
done <<< "$fblist"
modulesToRebase="$(echo $modulesToRebase | xargs)"
if [ -z "${modulesToRebase}" ]; then 
  success "All repositories are rebased! Nothing to do!"
  exit 0
fi

action "Starting creating FB..."

# Rebase each module in the list
rebasesCounter=0
for moduleToRebase in ${modulesToRebase}; do
    rebasesCounter=$((rebasesCounter+1))  
    org=$(echo $moduleToRebase | cut -d '@' -f1)
    item=$(echo $moduleToRebase | cut -d '@' -f2 )
    baseBranch=$(echo $moduleToRebase | cut -d '@' -f3)
    action "Creating branch feature/${FB_NAME} on ${baseBranch} of repository ${org}/${item}..."
    # Clone repository and rebase feature branch
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
    git checkout feature/${FB_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)
    git reset --hard origin/${baseBranch} &>/dev/null
    sed -Ei "s#<version>28(-exo|-meed)?-(M[0-9][0-9]|SNAPSHOT)</version>#<version>28-${FB_NAME}-SNAPSHOT</version>#g" pom.xml
    sed -Ei "s#<version>19(-exo|-meed)?-(M[0-9][0-9]|SNAPSHOT)</version>#<version>19-${FB_NAME}-SNAPSHOT</version>#g" pom.xml
    find -name pom.xml | xargs sed -Ei "s#\.x(-exo|-meed)?-SNAPSHOT#.x-${FB_NAME}-SNAPSHOT#g"
    git add -u && git commit -m "TASK-77677: Create FB ${FB_NAME} and update projects versions/dependencies" && git push origin feature/${FB_NAME} --force &>/dev/null || :
    popd &>/dev/null
done

# Wait for asynchronous jobs to complete
wait < <(jobs -p)

echo "================================================================================================="
success "Rebase done (${rebasesCounter} rebases)!"
