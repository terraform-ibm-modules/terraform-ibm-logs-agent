##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.1.6"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# SLZ ROKS Pattern
##############################################################################

module "landing_zone" {
  source                              = "git::https://github.com/terraform-ibm-modules/terraform-ibm-landing-zone//patterns//roks//module?ref=v7.3.0"
  region                              = var.region
  prefix                              = var.prefix
  tags                                = var.resource_tags
  add_atracker_route                  = false
  enable_transit_gateway              = false
  cluster_force_delete_storage        = true
  verify_cluster_network_readiness    = false
  use_ibm_cloud_private_api_endpoints = false
  ignore_vpcs_for_cluster_deployment  = ["management"]
}

##############################################################################
# COS instance
##############################################################################

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "8.16.4"
  resource_group_id      = module.resource_group.resource_group_id
  region                 = var.region
  cos_instance_name      = "${var.prefix}-cos"
  cos_tags               = var.resource_tags
  bucket_name            = "${var.prefix}-bucket"
  create_cos_bucket      = false
  retention_enabled      = false # disable retention for test environments - enable for stage/prod
  kms_encryption_enabled = false
}


##############################################################################
# COS buckets
##############################################################################

locals {
  logs_bucket_name    = "${var.prefix}-logs-data"
  metrics_bucket_name = "${var.prefix}-metrics-data"
}

module "buckets" {
  source  = "terraform-ibm-modules/cos/ibm//modules/buckets"
  version = "8.16.4"
  bucket_configs = [
    {
      bucket_name            = local.logs_bucket_name
      kms_encryption_enabled = false
      region_location        = var.region
      resource_instance_id   = module.cos.cos_instance_id
    },
    {
      bucket_name            = local.metrics_bucket_name
      kms_encryption_enabled = false
      region_location        = var.region
      resource_instance_id   = module.cos.cos_instance_id
    }
  ]
}

##############################################################################
# Observability:
# - Cloud Logs instance
##############################################################################

locals {
  cluster_resource_group_id = module.landing_zone.cluster_data["${var.prefix}-workload-cluster"].resource_group_id
  cluster_crn               = module.landing_zone.cluster_data["${var.prefix}-workload-cluster"].crn
}

module "cloud_logs" {
  source            = "terraform-ibm-modules/cloud-logs/ibm"
  version           = "1.0.0"
  resource_group_id = local.cluster_resource_group_id
  region            = var.region
  instance_name     = "${var.prefix}-cloud-logs"
  resource_tags     = var.resource_tags
  data_storage = {
    # logs and metrics buckets must be different
    logs_data = {
      enabled         = true
      bucket_crn      = module.buckets.buckets[local.logs_bucket_name].bucket_crn
      bucket_endpoint = module.buckets.buckets[local.logs_bucket_name].s3_endpoint_direct
    },
    metrics_data = {
      enabled         = true
      bucket_crn      = module.buckets.buckets[local.metrics_bucket_name].bucket_crn
      bucket_endpoint = module.buckets.buckets[local.metrics_bucket_name].s3_endpoint_direct
    }
  }
}

##############################################################################
# Trusted Profile
##############################################################################

locals {
  logs_agent_namespace = "ibm-agent"
  logs_agent_name      = "logs-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "1.0.5"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Logs agent Trusted Profile"
  # As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agent and routers sending logs.
  trusted_profile_policies = [{
    roles = ["Sender"]
    resources = [{
      service = "logs"
    }]
  }]
  # Set up fine-grained authorization for `logs-agent` running in ROKS cluster in `ibm-agent` namespace.
  trusted_profile_links = [{
    cr_type = "ROKS_SA"
    links = [{
      crn       = local.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}
