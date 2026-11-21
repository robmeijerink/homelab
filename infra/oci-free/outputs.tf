output "cluster_id" {
  value = module.oke.cluster_id
}

output "region" {
  value = var.region
}

output "kubernetes_version" {
  value = var.kubernetes_version
}

output "node_image_name" {
  value = module.oke.node_image_name
}

output "available_kubernetes_versions" {
  value = module.oke.available_kubernetes_versions
}
