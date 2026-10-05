output "org_ruleset_ids" {
  value = {
    baseline  = github_organization_ruleset.baseline_protection.id
    regulated = github_organization_ruleset.regulated_repo_protection.id
  }
}

output "property_schema" {
  value = {
    tier                 = github_organization_custom_properties.tier.property_name
    compliance_framework = github_organization_custom_properties.compliance_framework.property_name
    owning_team          = github_organization_custom_properties.owning_team.property_name
  }
}
