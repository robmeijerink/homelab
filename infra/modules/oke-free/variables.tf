variable "tenancy_id" {
  description = "Tenancy OCID, used to look up availability domains."
  type        = string
}

variable "compartment_id" {
  description = "Compartment OCID for all resources."
  type        = string
}

variable "name" {
  description = "Name prefix for every resource, also the cluster name."
  type        = string
  default     = "homelab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.name))
    error_message = "Use 2-21 lowercase letters, digits or dashes, starting with a letter."
  }
}

variable "vcn_cidr" {
  type    = string
  default = "10.0.0.0/16" # hygiene:allow
}

variable "public_subnet_cidr" {
  description = "Subnet for the Kubernetes API endpoint."
  type        = string
  default     = "10.0.0.0/24" # hygiene:allow
}

variable "worker_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24" # hygiene:allow
}

variable "pods_cidr" {
  type    = string
  default = "10.244.0.0/16" # hygiene:allow
}

variable "services_cidr" {
  type    = string
  default = "10.96.0.0/16" # hygiene:allow
}

variable "api_allowed_cidrs" {
  description = "CIDRs that may reach the Kubernetes API on 6443."
  type        = list(string)

  validation {
    condition     = length(var.api_allowed_cidrs) > 0 && alltrue([for c in var.api_allowed_cidrs : can(cidrhost(c, 0))])
    error_message = "Provide at least one valid CIDR."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version as offered by OKE, for example v1.36.1. Upgrading is a deliberate change."
  type        = string

  validation {
    condition     = can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "Use the form v1.36.1."
  }
}

variable "node_image_id" {
  description = "Worker image OCID. Null picks the newest aarch64 OKE image for kubernetes_version."
  type        = string
  default     = null
}

variable "node_count" {
  type    = number
  default = 2
}

variable "node_ocpus" {
  type    = number
  default = 1
}

variable "node_memory_gbs" {
  type    = number
  default = 6
}

variable "boot_volume_gbs" {
  description = "Boot volume per worker. local-path volumes live here."
  type        = number
  default     = 100
}

variable "ssh_public_key" {
  type    = string
  default = null
}

variable "enforce_always_free" {
  description = "Fail the plan when the node pool exceeds Always Free: 2 OCPU, 12 GB RAM, 200 GB block storage."
  type        = bool
  default     = true
}
