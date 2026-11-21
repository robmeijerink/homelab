variable "tenancy_id" {
  type = string
}

variable "compartment_id" {
  description = "Compartment for the cluster. Null uses the tenancy root."
  type        = string
  default     = null
}

variable "region" {
  description = "Home region of the tenancy. Always Free A1 and block storage only count there."
  type        = string
}

variable "oci_profile" {
  type    = string
  default = "DEFAULT"
}

variable "name" {
  type    = string
  default = "homelab"
}

variable "api_allowed_cidrs" {
  type = list(string)
}

variable "kubernetes_version" {
  type = string
}

variable "ssh_public_key" {
  type    = string
  default = null
}
