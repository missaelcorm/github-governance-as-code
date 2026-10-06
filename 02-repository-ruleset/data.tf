# Resolve the bypass team by slug rather than by numeric ID.
# count makes it conditional: bypass_team_slug = null means no bypass, and
# we must not then query GitHub for a team named null.
data "github_team" "bypass" {
  count = var.bypass_team_slug == null ? 0 : 1

  slug         = var.bypass_team_slug
  summary_only = true
}
