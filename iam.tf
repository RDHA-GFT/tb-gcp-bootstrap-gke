module "service-accounts" {
  source = "terraform-google-modules/service-accounts/google"
  version = "3.0.1"

  project_id = var.project_id
  names = [local.sa_name]
  project_roles = ""
}