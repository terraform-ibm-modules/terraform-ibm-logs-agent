# Lookup cluster name from ID. The is_vpc_cluster variable defines whether to use the VPC data block or the Classic data block
data "ibm_container_vpc_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 1 : 0
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

data "ibm_container_cluster" "cluster" {
  count             = var.is_vpc_cluster ? 0 : 1
  name              = var.cluster_id
  resource_group_id = var.cluster_resource_group_id
  wait_till         = var.wait_till
  wait_till_timeout = var.wait_till_timeout
}

# Download cluster config which is required to connect to cluster
data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].name : data.ibm_container_cluster.cluster[0].name
  resource_group_id = var.cluster_resource_group_id
  config_dir        = "${path.module}/kubeconfig"
  endpoint_type     = var.cluster_config_endpoint_type != "default" ? var.cluster_config_endpoint_type : null # null value represents default
}

locals {
  logs_agent_selected_log_source_paths = distinct(concat([for namespace in var.logs_agent_log_source_namespaces : "/var/log/containers/*_${namespace}_*.log"], var.logs_agent_selected_log_source_paths))
  logs_agent_iam_api_key               = var.logs_agent_iam_api_key != null ? var.logs_agent_iam_api_key : ""
  logs_agent_trusted_profile_id        = var.logs_agent_trusted_profile_id != null ? var.logs_agent_trusted_profile_id : ""
  cloud_logs_ingress_endpoint          = var.cloud_logs_ingress_endpoint != null ? var.cloud_logs_ingress_endpoint : ""
  logs_agent_additional_metadata = length(var.logs_agent_additional_metadata) > 0 ? merge([
    for metadata in var.logs_agent_additional_metadata : {
      (metadata.key) = metadata.value
  }]...) : {}                                                                                                                                       # DO NOT REMOVE "...", it is used to convert list of objects into a single object
  cluster_name = var.is_vpc_cluster ? data.ibm_container_vpc_cluster.cluster[0].resource_name : data.ibm_container_cluster.cluster[0].resource_name # Not publicly documented in provider. See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/4485
}

resource "helm_release" "logs_agent" {
  name             = var.logs_agent_name
  chart            = var.logs_agent_chart
  repository       = var.logs_agent_chart_location
  version          = var.logs_agent_chart_version
  namespace        = var.logs_agent_namespace
  create_namespace = true
  timeout          = 1200
  wait             = true
  recreate_pods    = true
  force_update     = true

  set {
    name  = "metadata.name"
    type  = "string"
    value = var.logs_agent_name
  }
  set {
    name  = "image.version"
    type  = "string"
    value = split("@", var.logs_agent_image_version)[0]
  }
  set {
    name  = "image.containerSha"
    type  = "string"
    value = strcontains(var.logs_agent_image_version, "@") ? split("@", var.logs_agent_image_version)[1] : ""
  }
  set {
    name  = "image.initContainerSha"
    type  = "string"
    value = strcontains(var.logs_agent_init_image_version, "@") ? split("@", var.logs_agent_init_image_version)[1] : ""
  }
  set {
    name  = "env.ingestionHost"
    type  = "string"
    value = local.cloud_logs_ingress_endpoint
  }
  set {
    name  = "env.ingestionPort"
    value = var.cloud_logs_ingress_port
  }
  set_sensitive {
    name  = "secret.iamAPIKey"
    type  = "string"
    value = local.logs_agent_iam_api_key
  }
  set {
    name  = "env.trustedProfileID"
    type  = "string"
    value = local.logs_agent_trusted_profile_id
  }
  set {
    name  = "env.iamMode"
    type  = "string"
    value = var.logs_agent_iam_mode
  }
  set {
    name  = "env.iamEnvironment"
    type  = "string"
    value = var.logs_agent_iam_environment
  }
  set {
    name  = "systemLogs"
    type  = "string"
    value = join("\\,", var.logs_agent_system_logs)
  }
  set {
    name  = "excludeLogSourcePaths"
    type  = "string"
    value = join("\\,", var.logs_agent_exclude_log_source_paths)
  }
  set {
    name  = "selectedLogSourcePaths"
    type  = "string"
    value = join("\\,", local.logs_agent_selected_log_source_paths)
  }
  set {
    name  = "clusterName"
    type  = "string"
    value = local.cluster_name
  }
  set {
    name  = "scc.create"
    value = var.logs_agent_enable_scc
  }
  set {
    name  = "enableMultiline"
    value = var.enable_multiline
  }

  set {
    name  = "includeAnnotations"
    value = var.enable_annotations
  }
  set {
    name  = "updateStrategy.maxUnavailable"
    value = var.max_unavailable
  }

  # dummy value hack to force update https://github.com/hashicorp/terraform-provider-helm/issues/515#issuecomment-813088122
  values = [
    yamlencode({
      tolerations        = var.logs_agent_tolerations
      additionalFilters  = var.log_filters
      resources          = var.logs_agent_resources
      additionalMetadata = local.logs_agent_additional_metadata
      dummy              = uuid()
    })
  ]


  provisioner "local-exec" {
    command     = "${path.module}/scripts/confirm-rollout-status.sh ${var.logs_agent_name} ${var.logs_agent_namespace}"
    interpreter = ["/bin/bash", "-c"]
    environment = {
      KUBECONFIG = data.ibm_container_cluster_config.cluster_config.config_file_path
    }
  }
}
