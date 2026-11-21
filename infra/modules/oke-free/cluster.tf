data "oci_identity_availability_domains" "this" {
  compartment_id = var.tenancy_id
}

data "oci_containerengine_node_pool_option" "all" {
  node_pool_option_id = "all"
  compartment_id      = var.compartment_id
}

locals {
  image_names = sort([
    for s in data.oci_containerengine_node_pool_option.all.sources : s.source_name
    if strcontains(s.source_name, "aarch64")
    && strcontains(s.source_name, "-OKE-${trimprefix(var.kubernetes_version, "v")}-")
    && !strcontains(s.source_name, "GPU")
    && !strcontains(s.source_name, "FIPS")
  ])
  image_ids       = { for s in data.oci_containerengine_node_pool_option.all.sources : s.source_name => s.image_id }
  node_image_name = var.node_image_id != null ? "custom" : try(local.image_names[length(local.image_names) - 1], "")
  node_image_id   = var.node_image_id != null ? var.node_image_id : lookup(local.image_ids, local.node_image_name, "")

  free_ocpus  = 2
  free_memory = 12
  free_block  = 200
}

resource "oci_containerengine_cluster" "this" {
  compartment_id     = var.compartment_id
  name               = var.name
  kubernetes_version = var.kubernetes_version
  vcn_id             = oci_core_vcn.this.id
  type               = "BASIC_CLUSTER"

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public.id
  }

  options {
    kubernetes_network_config {
      pods_cidr     = var.pods_cidr
      services_cidr = var.services_cidr
    }
  }
}

resource "oci_containerengine_node_pool" "a1" {
  cluster_id         = oci_containerengine_cluster.this.id
  compartment_id     = var.compartment_id
  name               = "${var.name}-a1"
  kubernetes_version = var.kubernetes_version
  node_shape         = "VM.Standard.A1.Flex"
  ssh_public_key     = var.ssh_public_key

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gbs
  }

  node_source_details {
    source_type             = "IMAGE"
    image_id                = local.node_image_id
    boot_volume_size_in_gbs = var.boot_volume_gbs
  }

  node_config_details {
    size = var.node_count

    dynamic "placement_configs" {
      for_each = data.oci_identity_availability_domains.this.availability_domains

      content {
        availability_domain = placement_configs.value.name
        subnet_id           = oci_core_subnet.workers.id
      }
    }

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  node_metadata = {
    user_data = base64encode(file("${path.module}/files/node-init.sh"))
  }

  initial_node_labels {
    key   = "homelab/pool"
    value = "a1"
  }

  lifecycle {
    ignore_changes = [node_source_details[0].image_id]

    precondition {
      condition     = local.node_image_id != ""
      error_message = "No aarch64 OKE image found for ${var.kubernetes_version}. Set node_image_id or pick another version."
    }

    precondition {
      condition = !var.enforce_always_free || (
        var.node_count * var.node_ocpus <= local.free_ocpus &&
        var.node_count * var.node_memory_gbs <= local.free_memory &&
        var.node_count * var.boot_volume_gbs <= local.free_block
      )
      error_message = "Node pool exceeds Always Free (2 OCPU, 12 GB RAM, 200 GB block storage in total)."
    }
  }
}
