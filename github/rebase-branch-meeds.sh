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
###

export FILTER_BRANCH_SQUELCH_WARNING=1  # filter-branch hide warnings
export DEFAULT_ORG="Meeds-io"

: "${BRANCH_NAME:?BRANCH_NAME is not set!}"

current_date=$(date '+%s')
action "Parsing branch repositories from catalog..."
modulesList=$(gh api -H 'Accept: application/vnd.github.v3.raw' "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/platform/seed_jobs_meeds_meed.groovy" | grep "project:")
modules_length=$(echo $modulesList | grep -o 'project:' | wc -w)
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
baseBranch=develop

# Iterate over each module and check rebase status
while IFS=']' read -r line; do
    counter=$((counter+1))
    item=$(echo $line | awk -F'project:' '{print $2}' | cut -d "," -f 1 | tr -d "'"| xargs)
    org=$(echo $line | awk -F'gitOrganization:' '{print $2}' | cut -d "," -f 1 | tr -d "'" | tr -d "]"| xargs)

    # Skip empty values
    [ -z "${item}" ] && continue
    [ -z "${org}" ] && org=${DEFAULT_ORG}

    # Check the comparison status between branches
    compareJson=$(gh api /repos/${org}/${item}/compare/${baseBranch}...${BRANCH_NAME})
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
        $branch_width "${baseBranch}...${BRANCH_NAME}" \
        $status_width "${colored_status}" \
        $ahead_behind_width "Ahead: $(echo -e $aheadbyMsg), Behind: $(echo -e $behindbyMsg)"

    # If not diverged, no rebase is needed
    if [ "${status:-}" != "diverged" ]; then
      continue
    fi

    modulesToRebase="${modulesToRebase} ${org}@${item}"
done <<< "$modulesList"
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
    item=$(echo $moduleToRebase | cut -d '@' -f2)
    action "Rebasing branch ${BRANCH_NAME} on ${baseBranch} of repository ${org}/${item}..."
    # Clone repository and rebase branch
    git clone git@github.com:${org}/${item}.git &>/dev/null
    pushd $item &>/dev/null
    git checkout ${BRANCH_NAME} &>/dev/null
    prev_head=$(git rev-parse --short HEAD)

    # Attempt rebase with recursive strategy, fallback to 'ours' if it fails
    if ! git rebase origin/${baseBranch} ${BRANCH_NAME} >/dev/null; then
      warn "Rebasing with recursive strategy has failed! Trying 'ours' strategy without detecting changes loss (helpful for detecting and removing backported commits)..."
      git rebase --abort || :
      if ! git rebase origin/${baseBranch} ${BRANCH_NAME} --strategy-option ours >/dev/null || [ ! -z "$(git diff -w origin/${BRANCH_NAME})" ]; then
        error "Could not rebase ${BRANCH_NAME}!"
        exit 1
      fi
    fi
    git log --oneline --cherry origin/${baseBranch}..HEAD
    if [ ! -z "$(git diff origin/${BRANCH_NAME} 2>/dev/null)" ]; then
      info "Reseting commits authors..."
      git filter-branch --commit-filter 'export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"; export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"; git commit-tree "$@"' -- origin/${baseBranch}..HEAD
      info "Changes before the rebase:"
      echo -e "\033[1;32m****\033[0m"
      git log HEAD..origin/${BRANCH_NAME} --oneline --pretty=format:"(%C(yellow)%h%Creset) %s"
      echo -e "\033[1;32m****\033[0m"
    else
      info "No changes detected!"
    fi
    new_head=$(git rev-parse --short HEAD)
    if [ "${prev_head}" != "${new_head}" ]; then
      info "Previous HEAD: \033[1;31m${prev_head}\033[0m, New HEAD: \033[1;32m${new_head}\033[0m."
      git push origin ${BRANCH_NAME} --force-with-lease | grep -v remote ||:
    fi
    popd &>/dev/null
done

echo "================================================================================================="
success "Rebase done (${rebasesCounter} rebases)!"
