#!/usr/bin/env bash
#
# Show a repo's classification and the rules it gets as a result.
#
# Run it, change the repo's `tier` property in the GitHub UI, run it again.
# Nothing else changes — not the repo's contents, not any Terraform — and the
# rules change.
#
# Usage:  ./show-rules.sh <org>/<repo>

set -euo pipefail

REPO="${1:?Usage: $0 <org>/<repo>}"
ORG="${REPO%%/*}"
BRANCH="$(gh api "repos/${REPO}" --jq '.default_branch')"

NAMES="$(mktemp)"
RULES="$(mktemp)"
trap 'rm -f "$NAMES" "$RULES"' EXIT

echo "== properties on ${REPO}"
gh api "repos/${REPO}/properties/values" --jq '.[] | "   \(.property_name) = \(.value)"'

# Each rule says which ruleset it came from by ID, and its `ruleset_source` is
# the org or repo that OWNS that ruleset — not the ruleset's own name. Printed
# raw, every org-level rule reads `Organization ruleset "my-org"`, which tells
# you nothing about which tier contributed it. So build an id -> name lookup.
# Listing org rulesets needs admin:org; without it we fall back to bare IDs.
gh api "orgs/${ORG}/rulesets" --jq '.[] | "\(.id)\torg  ruleset \"\(.name)\""' >>"$NAMES" 2>/dev/null || true
gh api "repos/${REPO}/rulesets" --jq '.[] | "\(.id)\trepo ruleset \"\(.name)\""' >>"$NAMES" 2>/dev/null || true

gh api "repos/${REPO}/rules/branches/${BRANCH}" \
  --jq '.[] | "\(.ruleset_id)\t\(.type)"' | sort -u >"$RULES"

echo
if [[ ! -s "$RULES" ]]; then
  echo "== no rules apply on ${BRANCH}"
  echo "   Check the repo is public if you're on a free org, and that"
  echo "   03-classification-and-org-rulesets actually applied."
  exit 0
fi

echo "== rules on ${BRANCH}, by the ruleset that contributes them"
while read -r id; do
  name="$(grep -m1 "^${id}$(printf '\t')" "$NAMES" | cut -f2- || true)"
  echo "   ${name:-ruleset ${id}}"
  grep "^${id}$(printf '\t')" "$RULES" | cut -f2- | sed 's/^/      /'
done < <(cut -f1 "$RULES" | sort -u)

# The same rule type appearing under two rulesets isn't a mistake. GitHub
# applies every matching ruleset and takes the strictest value for each rule.
# This is that merge, resolved — and it's where reclassifying a repo shows up
# even when the list of rule *types* barely moves.
echo
echo "== strictest values in effect (what a PR actually has to clear)"
gh api "repos/${REPO}/rules/branches/${BRANCH}" --jq '
  [.[] | select(.type == "pull_request") | .parameters] as $pr
  | if ($pr | length) == 0 then "   pull request not required"
    else "   approvals required: \([$pr[].required_approving_review_count] | max)",
         "   code owner review:  \([$pr[].require_code_owner_review] | any)"
    end'
