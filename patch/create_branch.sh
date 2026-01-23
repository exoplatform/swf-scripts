#!/bin/bash
#
# Patch Branch Creator for eXo Support
# Creates patch branches from existing tags with version suffix and branch protection
#
# Requirements:
#   GIT_TOKEN   - GitHub API token (environment variable)
#   REPOSITORIES - Comma-separated list of repo:version pairs
#                  Example: social:5.3.3,ecms:5.3.3
#   TASK_ID     - eXo Tribe Task ID (numbers only)
#
# Optional:
#   DRY_RUN     - Set to "true" to simulate without pushing changes
#   MAVEN_IMAGE - Docker image for Maven (default: maven:3.9.12)

set -euo pipefail

#######################################
# Configuration
#######################################
readonly SCRIPT_NAME="$(basename "$0")"
readonly MAVEN_IMAGE="${MAVEN_IMAGE:-maven:3.9.12}"
readonly MAVEN_SETTINGS="${MAVEN_SETTINGS:-/opt/prdacc/mavenpatch/settings.xml}"
readonly ORGANIZATIONS=("meeds-io" "exoplatform")
readonly DRY_RUN="${DRY_RUN:-false}"

# Regex patterns
readonly REPO_PATTERN='^([-0-9a-zA-Z]+:[0-9]+(\.[0-9]+)*(-[A-Za-z0-9]+)*(,)?)+$'
readonly TASK_ID_PATTERN='^[0-9]+$'

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

#######################################
# Logging functions
#######################################
log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[OK]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_header() {
    echo ""
    echo -e "${BLUE}## $*${NC}"
}

#######################################
# Cleanup function
#######################################
cleanup() {
    local exit_code=$?
    if [[ -n "${CURRENT_REPO:-}" && -d "${CURRENT_REPO}" ]]; then
        log_info "Cleaning up ${CURRENT_REPO}..."
        rm -rf "${CURRENT_REPO}"
    fi
    exit $exit_code
}

trap cleanup EXIT INT TERM

#######################################
# Usage function
#######################################
usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME}

Creates patch branches from existing tags with "-patched" version suffix
and configures branch protection rules.

Environment Variables:
    GIT_TOKEN       Required. GitHub API token with repo permissions.
    REPOSITORIES    Required. Comma-separated repo:version pairs.
                    Example: social:5.3.3,ecms:5.3.3
    TASK_ID         Required. eXo Tribe Task ID (numbers only).
    DRY_RUN         Optional. Set to "true" for simulation mode.
    MAVEN_IMAGE     Optional. Docker Maven image (default: ${MAVEN_IMAGE}).

Example:
    GIT_TOKEN=ghp_xxx REPOSITORIES=social:5.3.3 TASK_ID=12345 ${SCRIPT_NAME}
EOF
}

#######################################
# Validation functions
#######################################
validate_environment() {
    local has_error=false

    if [[ -z "${GIT_TOKEN:-}" ]]; then
        log_error "GIT_TOKEN environment variable is not set!"
        has_error=true
    fi

    if [[ -z "${REPOSITORIES:-}" ]]; then
        log_error "REPOSITORIES environment variable is not set!"
        has_error=true
    elif [[ ! "${REPOSITORIES}" =~ ${REPO_PATTERN} ]]; then
        log_error "Invalid REPOSITORIES format!"
        log_error "Expected: <repo1>:<version>,<repo2>:<version>,..."
        log_error "Example: social:5.3.3,ecms:5.3.3"
        has_error=true
    fi

    if [[ -z "${TASK_ID:-}" ]]; then
        log_error "TASK_ID environment variable is not set!"
        has_error=true
    elif [[ ! "${TASK_ID}" =~ ${TASK_ID_PATTERN} ]]; then
        log_error "Invalid TASK_ID format! Only digits are accepted."
        has_error=true
    fi

    if [[ "${has_error}" == "true" ]]; then
        echo ""
        usage
        exit 1
    fi
}

validate_prerequisites() {
    local missing=()

    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")
    command -v docker &>/dev/null || missing+=("docker")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        exit 1
    fi
}

#######################################
# Git helper functions
#######################################
find_organization() {
    local repo="$1"
    local tag="$2"

    for org in "${ORGANIZATIONS[@]}"; do
        if git ls-remote --tags "git@github.com:${org}/${repo}.git" "${tag}" 2>/dev/null | grep -q .; then
            echo "${org}"
            return 0
        fi
    done

    return 1
}

branch_exists() {
    local org="$1"
    local repo="$2"
    local branch="$3"

    git ls-remote --heads "git@github.com:${org}/${repo}.git" "${branch}" 2>/dev/null | grep -q .
}

clone_repository() {
    local org="$1"
    local repo="$2"
    local tag="$3"

    git -c advice.detachedHead=false clone --branch "${tag}" --depth=1 --quiet "git@github.com:${org}/${repo}.git"
}

#######################################
# Maven helper function
#######################################
run_maven() {
    local repo_path="$1"
    shift

    sudo docker run --rm \
        --volume "$(readlink -f "${repo_path}"):/home" \
        --volume "${MAVEN_SETTINGS}:/root/.m2/settings.xml:ro" \
        --workdir /home \
        --dns="8.8.8.8" \
        --dns="8.8.4.4" \
        --sysctl net.ipv6.conf.all.disable_ipv6=1 \
        "${MAVEN_IMAGE}" \
        mvn "$@"
}

#######################################
# GitHub API helper function
#######################################
set_branch_protection() {
    local org="$1"
    local repo="$2"
    local branch="$3"
    local encoded_branch

    # URL encode the branch name (/ -> %2F)
    encoded_branch="${branch//\//%2F}"

    local protection_rules
    protection_rules=$(cat <<'EOF'
{
    "required_status_checks": {
        "strict": true,
        "contexts": ["PR Build"]
    },
    "enforce_admins": true,
    "required_pull_request_reviews": {
        "dismiss_stale_reviews": true,
        "required_approving_review_count": 1
    },
    "restrictions": null
}
EOF
    )

    local response
    local http_code

    response=$(curl --silent --show-error \
        --request PUT \
        --url "https://api.github.com/repos/${org}/${repo}/branches/${encoded_branch}/protection" \
        --header 'Accept: application/vnd.github+json' \
        --header "Authorization: Bearer ${GIT_TOKEN}" \
        --header 'Content-Type: application/json' \
        --data "${protection_rules}" \
        --write-out '\n%{http_code}' \
        2>&1)

    http_code=$(echo "${response}" | tail -n1)

    if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]; then
        return 0
    else
        log_error "Failed to set branch protection (HTTP ${http_code})"
        log_error "Response: $(echo "${response}" | head -n -1)"
        return 1
    fi
}

#######################################
# Process a single repository
#######################################
process_repository() {
    local repo="$1"
    local tag_version="$2"
    local patch_branch="patch/${tag_version}"

    log_header "Module: ${repo}:${tag_version}"

    # Clean up any existing directory
    rm -rf "${repo}" 2>/dev/null || true
    CURRENT_REPO="${repo}"

    # Find organization
    log_info "Finding organization for ${repo}..."
    local organization
    if ! organization=$(find_organization "${repo}" "${tag_version}"); then
        log_error "Tag ${tag_version} not found in any organization!"
        return 1
    fi
    log_success "Found in ${organization}"

    # Check if patch branch already exists
    log_info "Checking if ${patch_branch} already exists..."
    if branch_exists "${organization}" "${repo}" "${patch_branch}"; then
        log_error "Branch ${patch_branch} already exists!"
        return 1
    fi
    log_success "Branch ${patch_branch} does not exist"

    # Clone repository
    log_info "Cloning ${organization}/${repo}..."
    if ! clone_repository "${organization}" "${repo}" "${tag_version}"; then
        log_error "Failed to clone repository!"
        return 1
    fi
    log_success "Repository cloned"

    # Create patch branch
    log_info "Creating branch ${patch_branch}..."
    git -C "${repo}" checkout -b "${patch_branch}" --quiet
    log_success "Branch created locally"

    # Handle Maven project
    if [[ -f "${repo}/pom.xml" ]]; then
        log_info "Maven project detected. Updating version..."
        run_maven "${repo}" -ntp versions:set \
            -DgenerateBackupPoms=false \
            -DnewVersion="${tag_version}-patched"
        log_success "Version updated to ${tag_version}-patched"

        log_info "Staging pom.xml changes..."
        git -C "${repo}" diff "${tag_version}" --name-only \
            | grep -E 'pom\.xml$' \
            | xargs -I {} git -C "${repo}" add {}
        log_success "pom.xml files staged"
    fi

    # Create changelog file
    log_info "Creating patches-changelog.txt..."
    cat > "${repo}/patches-changelog.txt" <<EOF
              $(date +%Y-%m-%d) eXo Support <support@exoplatform.com>

   # ${tag_version} Patches changelog:

EOF
    git -C "${repo}" add patches-changelog.txt
    log_success "Changelog file created"

    # Commit changes
    local commit_msg="TASK-${TASK_ID}: Create Patch Branch for version ${tag_version}"
    log_info "Committing: ${commit_msg}"
    git -C "${repo}" commit --quiet -m "${commit_msg}"
    log_success "Changes committed"

    # Push branch
    if [[ "${DRY_RUN}" == "true" ]]; then
        log_warn "DRY RUN: Skipping push to origin"
    else
        log_info "Pushing ${patch_branch} to origin..."
        git -C "${repo}" push --quiet -u origin "${patch_branch}" 2>&1 | grep -v remote || true
        log_success "Branch pushed"

        # Set branch protection
        log_info "Setting branch protection rules..."
        if set_branch_protection "${organization}" "${repo}" "${patch_branch}"; then
            log_success "Branch protection configured"
        else
            log_warn "Failed to set branch protection. Please configure manually."
        fi
    fi

    # Cleanup
    rm -rf "${repo}"
    CURRENT_REPO=""

    log_success "Completed processing ${repo}:${tag_version}"
}

#######################################
# Main function
#######################################
main() {
    echo "####################################"
    echo "Patch Branch Creator for eXo Support"
    echo "####################################"
    echo ""

    validate_prerequisites
    validate_environment

    log_info "Repositories: ${REPOSITORIES}"
    log_info "Task ID: ${TASK_ID}"
    [[ "${DRY_RUN}" == "true" ]] && log_warn "DRY RUN MODE ENABLED"
    echo ""
    echo "####################################"

    # Parse repositories
    local repos
    IFS=',' read -ra repos <<< "${REPOSITORIES}"

    local failed=()
    local succeeded=()

    for entry in "${repos[@]}"; do
        local repo="${entry%%:*}"
        local tag_version="${entry#*:}"

        if process_repository "${repo}" "${tag_version}"; then
            succeeded+=("${entry}")
        else
            failed+=("${entry}")
            log_error "Failed to process ${entry}"
        fi
    done

    # Summary
    echo ""
    echo "####################################"
    echo "Summary"
    echo "####################################"
    log_success "Succeeded: ${#succeeded[@]}"
    for entry in "${succeeded[@]:-}"; do
        [[ -n "${entry}" ]] && echo "  - ${entry}"
    done

    if [[ ${#failed[@]} -gt 0 ]]; then
        log_error "Failed: ${#failed[@]}"
        for entry in "${failed[@]}"; do
            echo "  - ${entry}"
        done
        exit 1
    fi

    log_success "All repositories processed successfully!"
}

# Run main function
main "$@"