# --- Classification layer -------------------------------------------------
#
# Custom properties are what every repo in the org gets tagged with. The
# org rulesets in rulesets.tf don't reference individual repo names at all
# — they match on these property values instead. Tag a repo correctly and
# it inherits the right protections automatically.
#
# PLAN NOTE: organization custom properties are available on every
# GitHub plan, free included — defining this schema and assigning values
# needs no Team or Enterprise subscription. It's the *enforcement* half
# (rulesets.tf) that has plan constraints. See
# ../docs/plan-requirements.md.
#
# NOTE ON PROVIDER VERSIONS: custom-property support landed comparatively
# recently in integrations/github and its resource/attribute names have
# shifted across minor versions while the feature stabilized. Before you
# apply this against a real org, diff the resource schema below against
# the registry docs for whatever provider version you've pinned:
# https://registry.terraform.io/providers/integrations/github/latest/docs
# (search "custom_propert"). Don't trust a slide — or this file — over
# `terraform providers schema -json` on your own pinned version.

resource "github_organization_custom_properties" "tier" {
  property_name = "tier"
  value_type    = "single_select"
  required      = true
  default_value = "standard"
  description   = "Governance tier. Drives which org rulesets apply to this repo."

  allowed_values = [
    "standard",  # default protections only
    "sensitive", # customer data, internal-facing
    "regulated", # in scope for a compliance framework (PCI, SOC 2, HIPAA...)
  ]

  values_editable_by = "org_actors"
}

resource "github_organization_custom_properties" "compliance_framework" {
  property_name = "compliance_framework"
  value_type    = "multi_select"
  required      = false
  description   = "Compliance framework(s) this repository is in scope for, if any."

  allowed_values = [
    "pci-dss",
    "soc2",
    "hipaa",
  ]

  values_editable_by = "org_actors"
}

resource "github_organization_custom_properties" "owning_team" {
  property_name = "owning_team"
  value_type    = "string"
  required      = false
  description   = "Team slug responsible for this repository."

  # Deliberately more permissive than the other two: letting repo admins
  # correct their own owning_team value is a reasonable self-service
  # escape hatch. Letting them set their own `tier` would not be — see
  # docs/operational-realities.md on drift for why that distinction
  # matters.
  values_editable_by = "org_and_repo_actors"
}
