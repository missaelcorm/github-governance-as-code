#!/usr/bin/env bash
#
# Show a repo's classification and the rules it gets as a result.
#
# Run it, change the repo's `tier` property in the GitHub UI, run it again.
# Nothing else changes — not the repo's contents, not any Terraform — and
# the rule list grows.
#
# Usage:  ./show-rules.sh <org>/<repo>

set -euo pipefail

REPO="${1:?Usage: $0 <org>/<repo>}"
BRANCH="$(gh api "repos/${REPO}" --jq '.default_branch')"

echo "== properties on ${REPO}"
gh api "repos/${REPO}/properties/values" \
  --jq '.[] | "   \(.property_name) = \(.value)"'

# This endpoint returns the aggregate of every ruleset matching the branch,
# repo-level and org-level merged. It's the only honest answer to "what is
# enforced here" — reading one ruleset's definition is not.
echo
echo "== rules on ${BRANCH}"
gh api "repos/${REPO}/rules/branches/${BRANCH}" \
  --jq 'if length == 0 then "   (none — on a free org, check the repo is public)"
        else (.[] | "   \(.type)   <- \(.ruleset_source_type) ruleset \"\(.ruleset_source)\"") end'
