provider "oci" {
  config_file_profile = var.oci_profile
  region              = var.region
}

module "oke" {
  source = "../modules/oke-free"

  tenancy_id         = var.tenancy_id
  compartment_id     = coalesce(var.compartment_id, var.tenancy_id)
  name               = var.name
  api_allowed_cidrs  = var.api_allowed_cidrs
  kubernetes_version = var.kubernetes_version
  ssh_public_key     = var.ssh_public_key
}
