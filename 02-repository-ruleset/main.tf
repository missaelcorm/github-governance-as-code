# A single repository-level ruleset — the modern, enforced replacement for
# github_branch_protection. This is what section 4 of the talk contrasts
# with classic branch protection, and it's what you'd hand-write per repo
# before adopting the org-level, property-driven pattern in module 03.
#
# Note: rules.deletion / rules.update / rules.creation being `true` means
# that action is *restricted* (blocked for anyone without bypass rights),
# not that it's allowed — an easy footgun to misread on first pass.
resource "github_repository_ruleset" "protect_default_branch" {
  name        = "protect-default-branch"
  repository  = var.repository_name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # Deliberately a MODEST baseline: block the destructive stuff, require a
  # review and green CI. Linear history, signed commits and code-owner review
  # are left to module 03's regulated tier, so that reclassifying a repo
  # visibly adds something. A repo ruleset that already requires everything
  # makes the org-level tiers look like they do nothing.
  rules {
    deletion         = true # block branch deletion
    non_fast_forward = true # block force-push

    pull_request {
      required_approving_review_count = var.required_review_count
      dismiss_stale_reviews_on_push   = true
    }

    required_status_checks {
      strict_required_status_checks_policy = true

      dynamic "required_check" {
        for_each = var.required_status_checks
        content {
          context = required_check.value
        }
      }
    }
  }

  # Iterates over the data source's instances, which is 0 or 1 — so this
  # emits a bypass_actors block only when bypass_team_slug was set.
  dynamic "bypass_actors" {
    for_each = data.github_team.bypass
    content {
      # The data source exposes the team ID as a string; actor_id is
      # typed as a number, hence the conversion.
      actor_id    = tonumber(bypass_actors.value.id)
      actor_type  = "Team"
      bypass_mode = "pull_request"
    }
  }
}
