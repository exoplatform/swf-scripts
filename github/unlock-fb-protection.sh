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

DELAY="${DELAY:-5}"

command -v gh >/dev/null 2>&1 || die "'gh' CLI is not installed"

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

while IFS=']' read -r line; do
    item="$(awk -F'project:' '{print $2}' <<< "$line" | cut -d',' -f1 | tr -d "'" | xargs)"
    org="$(awk -F'gitOrganization:' '{print $2}' <<< "$line" | cut -d',' -f1 | tr -d "']" | xargs)"

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

echo "Performing unlock protection..."

for module in "${MODULES_ARR[@]}"; do
    echo "Unlocking protection on ${module}:feature/${FB_NAME}"
    gh api \
        --method DELETE \
        -H 'Accept: application/vnd.github.luke-cage-preview+json' \
        "/repos/${module}/branches/feature/${FB_NAME}/protection" || true
done

echo "Branches unlocked."
echo "You have ${DELAY} minutes to perform actions ⏳"

sleep "${DELAY}m"

# ---------- Restore Protection ----------

echo "Restoring branch protection..."

for module in "${MODULES_ARR[@]}"; do
    echo "Restoring protection on ${module}:feature/${FB_NAME}"
    curl -fsSL -X PUT \
        "https://api.github.com/repos/${module}/branches/feature/${FB_NAME}/protection" \
        -H 'Accept: application/vnd.github.luke-cage-preview+json' \
        -H "Authorization: Bearer ${GH_TOKEN:?GH_TOKEN is required}" \
        -H 'Content-Type: application/json' \
        -d '{
            "required_status_checks": {
                "strict": true,
                "contexts": ["PR Build"]
            },
            "required_pull_request_reviews": {
                "dismiss_stale_reviews": true,
                "require_code_owner_reviews": false,
                "required_approving_review_count": 1
            },
            "allow_force_pushes": true,
            "enforce_admins": false,
            "restrictions": null
        }'
done

echo "Branches are now protected ✅"
