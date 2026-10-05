# Resolve the bypass team by slug rather than by numeric ID — see the
# longer note in ../03-classification-and-org-rulesets/data.tf for why.
#
# count makes the lookup conditional: bypass_team_slug = null means "no
# bypass at all", and in that case we must not query GitHub for a team
# named null.
data "github_team" "bypass" {
  count = var.bypass_team_slug == null ? 0 : 1

  slug         = var.bypass_team_slug
  summary_only = true
}
