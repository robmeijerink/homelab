output "cluster_id" {
  value = oci_containerengine_cluster.this.id
}

output "node_image_name" {
  value = var.node_image_name
}

output "available_kubernetes_versions" {
  value = data.oci_containerengine_node_pool_option.all.kubernetes_versions
}

output "vcn_id" {
  value = oci_core_vcn.this.id
}

output "public_subnet_id" {
  value = oci_core_subnet.public.id
}

output "worker_subnet_id" {
  value = oci_core_subnet.workers.id
}
