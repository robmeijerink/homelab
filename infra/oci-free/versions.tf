terraform {
  required_version = ">= 1.10"

  backend "s3" {}

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "9.14.0"
    }
  }
}
