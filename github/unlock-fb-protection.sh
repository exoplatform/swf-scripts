#!/usr/bin/env bash
set -Eeuo pipefail

# =========================
# Args:
#   FB_NAME   (mandatory) : Feature branch name (without feature/)
#   MODULES   (mandatory) : comma or space separated list org/repo
#   DELAY     (optional)  : minutes (default: 5)
# =========================

# ---------- Helpers ----------

die() {
    echo "ERROR: $*" >&2
    exit 1
}

# Case-insensitive membership check
# Usage: has_array_value "org" "repo" "${modules[@]}"
has_array_value() {
    local org="${1,,}"
    local item="${2,,}"
    shift 2

    local wanted="${org}/${item}"

    for entry in "$@"; do
        [[ "${entry,,}" == "$wanted" ]] && return 0
    done
    return 1
}

# ---------- Preconditions ----------

: "${FB_NAME:?FB_NAME is required}"
: "${MODULES:?MODULES is required}"
: "${GH_TOKEN:?GH_TOKEN is required}"

# Let gh pick up the token (required in Jenkins where 'gh auth login' is not run)
export GH_TOKEN

DELAY="${DELAY:-5}"

command -v gh >/dev/null 2>&1 || die "'gh' CLI is not installed"
command -v jq >/dev/null 2>&1 || die "'jq' is not installed"

# Normalize FB name once
FB_NAME_LC="$(echo "${FB_NAME//-/}" | tr '[:upper:]' '[:lower:]')"

echo "Parsing FB '${FB_NAME}' Seed Job Configuration..."

# Normalize MODULES → array
MODULES="${MODULES//,/ }"
read -r -a MODULES_ARR <<< "${MODULES}"
MODULES_LENGTH="${#MODULES_ARR[@]}"

echo "Modules provided: ${MODULES_LENGTH}"

# ---------- Fetch catalog ----------

echo "Parsing FB repositories from catalog..."

fblist="$(gh api \
    -H 'Accept: application/vnd.github.v3.raw' \
    "/repos/exoplatform/swf-jenkins-pipeline/contents/dsl-jobs/FB/seed_jobs_FB_${FB_NAME_LC}.groovy"
)"

modules_length="$(grep -o 'project:' <<< "$fblist" | wc -l)"
echo "Modules in catalog: ${modules_length}"

# ---------- Validation ----------

echo "Checking modules..."

counter=0
last_org=""

while IFS=']' read -r line; do
    item="$(awk -F'project:' '{print $2}' <<< "$line" | cut -d',' -f1 | tr -d "'" | tr -d "]" | xargs)"
    org="$(awk -F'gitOrganization:' '{print $2}' <<< "$line" | cut -d',' -f1 | tr -d "']" | xargs)"
    if [ -z "${org}" ] && [ -n "${last_org}" ]; then org="${last_org}"; elif [ -n "${org}" ]; then last_org="${org}"; fi

    [[ -z "$item" || -z "$org" ]] && continue

    if has_array_value "$org" "$item" "${MODULES_ARR[@]}"; then
        counter=$((counter + 1))
    fi
done <<< "$fblist"

if [[ "$counter" -ne "$MODULES_LENGTH" ]]; then
    die "Check failed: $counter / $MODULES_LENGTH modules matched catalog"
fi

echo "Checks OK."

# ---------- Unlock Protection ----------

# Ref covered by the ruleset (used to locate rulesets to delete)
FB_REF="refs/heads/feature/${FB_NAME}"

# Deletes every branch-scoped ruleset whose conditions match the FB ref.
# 404 for an individual ruleset is tolerated (already gone); other failures abort.
delete_branch_rulesets() {
    local module="$1"
    local ids

    ids="$(gh api --paginate "/repos/${module}/rulesets" 2>/dev/null \
        | jq -r --arg ref "${FB_REF}" \
            '[.[] | select(.target == "branch") | select(any(.conditions.ref_name.include // [] | .[]; . == $ref)) | .id] | .[]' \
        2>/dev/null)" || return 1

    if [[ -z "${ids}" ]]; then
        echo "  No ruleset found for ${FB_REF}"
        return 0
    fi

    for id in ${ids}; do
        local output http_code
        output="$(gh api --method DELETE "/repos/${module}/rulesets/${id}" --include 2>&1)" || true
        http_code="$(awk 'NR==1 {print $2}' <<<"${output}")"
        if [[ "${http_code}" =~ ^2 ]]; then
            echo "  Ruleset ${id} deleted"
        elif [[ "${http_code}" == "404" ]]; then
            echo "  Ruleset ${id} already gone"
        else
            echo "  ERROR: could not delete ruleset ${id} (HTTP ${http_code})" >&2
            echo "${output}" >&2
            return 1
        fi
    done
}

# Deletes the legacy branch protection if present; 404 (not protected) is tolerated,
# other failures abort.
delete_legacy_protection() {
    local module="$1"
    local output http_code

    output="$(gh api \
        --method DELETE \
        -H 'Accept: application/vnd.github.v3+json' \
        "/repos/${module}/branches/feature/${FB_NAME}/protection" \
        --include 2>&1)" || true
    http_code="$(awk 'NR==1 {print $2}' <<<"${output}")"

    if [[ "${http_code}" =~ ^2 ]]; then
        echo "  Legacy branch protection deleted"
    elif [[ "${http_code}" == "404" ]]; then
        echo "  No legacy branch protection to delete"
    else
        echo "  ERROR: could not delete legacy protection (HTTP ${http_code})" >&2
        echo "${output}" >&2
        return 1
    fi
}

echo "Performing unlock protection..."

for module in "${MODULES_ARR[@]}"; do
    echo "Unlocking protection on ${module}:feature/${FB_NAME}"

    # New mechanism: repository rulesets
    delete_branch_rulesets "${module}"

    # Backward compatibility: legacy branch protection (still set on some repos)
    delete_legacy_protection "${module}"
done

echo "Branches unlocked."
echo "You have ${DELAY} minutes to perform actions ⏳"

sleep "${DELAY}m"

# ---------- Restore Protection ----------

# Recreates a branch-scoped ruleset for the FB ref, mirroring the legacy
# protection rule (strict PR Build, 1 approving review, dismiss stale reviews,
# force pushes allowed).
create_branch_ruleset() {
    local module="$1"
    local payload

    payload="$(cat <<EOF
{
    "name": "feature-branch-protection-${FB_NAME}",
    "target": "branch",
    "enforcement": "active",
    "conditions": {
        "ref_name": {
            "include": ["${FB_REF}"],
            "exclude": []
        }
    },
    "rules": [
        {
            "type": "required_status_checks",
            "parameters": {
                "strict_required_status_checks_policy": true,
                "required_status_checks": [
                    {"context": "PR Build"}
                ]
            }
        },
        {
            "type": "pull_request",
            "parameters": {
                "dismiss_stale_reviews_on_push": true,
                "require_code_owner_review": false,
                "require_last_push_approval": false,
                "required_approving_review_count": 1,
                "required_review_thread_resolution": false
            }
        }
    ]
}
EOF
    )"

    echo "Restoring ruleset on ${module}:feature/${FB_NAME}"
    local output http_code
    output="$(gh api \
        --method POST \
        -H 'Accept: application/vnd.github+json' \
        "/repos/${module}/rulesets" \
        --input - <<<"${payload}" \
        --include 2>&1)" || true
    http_code="$(awk 'NR==1 {print $2}' <<<"${output}")"

    if [[ "${http_code}" =~ ^2 ]]; then
        echo "  Ruleset created"
    else
        local error_msg
        error_msg="$(echo "${output}" | tail -n +2 | jq -r '.message // empty' 2>/dev/null || true)"
        echo "  ERROR: could not restore ruleset (HTTP ${http_code}): ${error_msg:-see output below}" >&2
        echo "${output}" >&2
        return 1
    fi
}

echo "Restoring branch protection..."

for module in "${MODULES_ARR[@]}"; do
    create_branch_ruleset "${module}"
done

echo "Branches are now protected ✅"
