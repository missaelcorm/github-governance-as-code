# --- Enforcement layer -----------------------------------------------------
#
# One ruleset per protection level, targeting repos by the properties in
# properties.tf rather than by name. Tag a repo `tier = regulated` — from the
# UI, the API, or Terraform — and it picks up regulated_repo_protection. No
# per-repo apply, no PR against this repo at all.
#
# The two rulesets are ADDITIVE, not alternatives: GitHub merges every ruleset
# matching a ref and takes the most restrictive value per rule.
#
# PLAN NOTE: all of this applies on a free org — the rulesets are created and
# target correctly. A free org just won't *enforce* them (needs GitHub Team),
# and only applies rulesets to public repos. See ../docs/plan-requirements.md.
#
# Every rule below works on every plan. Two that would fit here are Enterprise
# Cloud only and left out on purpose:
#   - Restrict commit metadata (commit message / author email patterns) —
#     put this in CI as a required status check instead.
#   - Restrict branch names (branch_name_pattern) — scope ref_name.include
#     per branch namespace instead.

resource "github_organization_ruleset" "baseline_protection" {
  name        = "baseline-protection"
  target      = "branch"
  enforcement = var.ruleset_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }

    repository_property {
      # Every repo carries a `tier` (it's `required = true` with a
      # default), so listing all three values here means "every repo in
      # the org" — the floor, not the ceiling.
      include {
        name            = "tier"
        property_values = ["standard", "sensitive", "regulated"]
      }
    }
  }

  rules {
    deletion         = true
    non_fast_forward = true

    pull_request {
      required_approving_review_count = 1
      dismiss_stale_reviews_on_push   = true
    }
  }

  bypass_actors {
    # The data source exposes the team ID as a string; actor_id is typed
    # as a number, hence the conversion.
    actor_id    = tonumber(data.github_team.bypass.id)
    actor_type  = "Team"
    bypass_mode = "always"
  }
}

resource "github_organization_ruleset" "regulated_repo_protection" {
  name        = "regulated-repo-protection"
  target      = "branch"
  enforcement = var.ruleset_enforcement

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }

    repository_property {
      include {
        name            = "tier"
        property_values = ["regulated"]
      }
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true
    required_linear_history = true
    required_signatures     = true

    pull_request {
      required_approving_review_count = 2
      require_code_owner_review       = true
      dismiss_stale_reviews_on_push   = true
      require_last_push_approval      = true
    }

    required_status_checks {
      strict_required_status_checks_policy = true

      required_check {
        context = "ci/build"
      }
      required_check {
        context = "ci/test"
      }
      required_check {
        context = "security/sast"
      }
    }
  }

  bypass_actors {
    actor_id    = tonumber(data.github_team.bypass.id)
    actor_type  = "Team"
    bypass_mode = "pull_request"
  }
}
