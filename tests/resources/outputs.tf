##############################################################################
# Outputs
##############################################################################

output "region" {
  value       = var.region
  description = "Region where SLZ ROKS Cluster is deployed."
}

output "prefix" {
  value       = module.landing_zone.prefix
  description = "prefix"
}

output "workload_cluster_id" {
  value       = module.ocp_base.cluster_id
  description = "ID of the workload cluster."
}

output "workload_cluster_crn" {
  value       = module.ocp_base.cluster_crn
  description = "CRN of the workload cluster."
}

output "cluster_resource_group_id" {
  value       = module.ocp_base.resource_group_id
  description = "Resource group ID of the workload cluster."
}

output "trusted_profile_id" {
  value       = module.trusted_profile.trusted_profile.id
  description = "The ID of the trusted profile."
}

output "cloud_logs_instance_name" {
  value       = module.cloud_logs.name
  description = "The name of the provisioned IBM Cloud Logs instance."
}

output "cloud_logs_ingress_private_endpoint" {
  value       = module.cloud_logs.ingress_private_endpoint
  description = "The private ingress endpoint of the provisioned Cloud Logs instance."
}
