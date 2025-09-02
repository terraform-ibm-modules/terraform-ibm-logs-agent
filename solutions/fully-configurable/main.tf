##############################################################################
# Logs Agent
##############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = local.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].name : data.ibm_container_cluster.cluster[0].name
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = local.cluster_config_endpoint_type != "default" ? local.cluster_config_endpoint_type : null
}

locals {
  cluster_config_endpoint_type = var.cluster_config_endpoint_type
  is_vpc_cluster               = var.is_vpc_cluster
}

module "logs_agent" {
  source                       = "../.."
  cluster_id                   = var.cluster_id
  cluster_resource_group_id    = var.cluster_resource_group_id
  cluster_config_endpoint_type = local.cluster_config_endpoint_type
  # Logs Agent
  logs_agent_chart                     = var.logs_agent_chart
  logs_agent_chart_location            = var.logs_agent_chart_location
  logs_agent_chart_version             = var.logs_agent_chart_version
  logs_agent_image_version             = var.logs_agent_image_version
  logs_agent_name                      = var.logs_agent_name
  logs_agent_namespace                 = var.logs_agent_namespace
  logs_agent_trusted_profile_id        = var.logs_agent_trusted_profile_id
  logs_agent_iam_api_key               = var.logs_agent_iam_api_key
  logs_agent_tolerations               = var.logs_agent_tolerations
  logs_agent_system_logs               = var.logs_agent_system_logs
  logs_agent_exclude_log_source_paths  = var.logs_agent_exclude_log_source_paths
  logs_agent_selected_log_source_paths = var.logs_agent_selected_log_source_paths
  logs_agent_log_source_namespaces     = var.logs_agent_log_source_namespaces
  logs_agent_iam_mode                  = var.logs_agent_iam_mode
  logs_agent_iam_environment           = var.logs_agent_iam_environment
  logs_agent_additional_metadata       = var.logs_agent_additional_metadata
  logs_agent_enable_scc                = var.is_ocp_cluster
  logs_agent_resources                 = var.logs_agent_resources
  cloud_logs_ingress_endpoint          = var.cloud_logs_ingress_endpoint
  cloud_logs_ingress_port              = var.cloud_logs_ingress_port
  is_vpc_cluster                       = var.is_vpc_cluster
  wait_till                            = var.wait_till
  wait_till_timeout                    = var.wait_till_timeout
  enable_multiline                     = var.enable_multiline
  enable_annotations                   = var.enable_annotations
  log_filters                          = var.log_filters
}
