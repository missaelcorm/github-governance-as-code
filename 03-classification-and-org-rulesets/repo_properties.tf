# --- Example: classifying a repo via Terraform -----------------------------
#
# Classification doesn't have to happen in Terraform — that's rather the
# point of the pattern — the talk sets the value from the GitHub UI, and an
# onboarding pipeline is just as valid. But
# it's equally valid to manage property values here when a repo's
# classification is itself something you want reviewed via pull request.
#
# Leave this resource commented out before the live demo — the whole
# point is to tag payments-service *outside* Terraform and watch
# regulated_repo_protection apply on its own. Uncomment afterwards to show
# the Terraform-managed alternative.

# resource "github_repository_custom_property" "payments_service_tier" {
#   repository       = "payments-service"
#   property_name    = github_organization_custom_properties.tier.property_name
#   property_type    = "single_select"
#   property_value   = ["regulated"]
# }
#
# resource "github_repository_custom_property" "payments_service_framework" {
#   repository       = "payments-service"
#   property_name    = github_organization_custom_properties.compliance_framework.property_name
#   property_type    = "multi_select"
#   property_value   = ["pci-dss"]
# }
