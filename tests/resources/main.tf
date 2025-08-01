##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.3.0"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

########################################################################################################################
# VPC + Subnet + Public Gateway
#
# NOTE: This is a very simple VPC with single subnet in a single zone with a public gateway enabled, that will allow
# all traffic ingress/egress by default.
# For production use cases this would need to be enhanced by adding more subnets and zones for resiliency, and
# ACLs/Security Groups for network security.
########################################################################################################################

resource "ibm_is_vpc" "vpc" {
  name                      = "${var.prefix}-vpc"
  resource_group            = module.resource_group.resource_group_id
  address_prefix_management = "auto"
  tags                      = var.resource_tags
}

resource "ibm_is_public_gateway" "gateway" {
  name           = "${var.prefix}-gateway-1"
  vpc            = ibm_is_vpc.vpc.id
  resource_group = module.resource_group.resource_group_id
  zone           = "${var.region}-1"
}

resource "ibm_is_subnet" "subnet_zone_1" {
  name                     = "${var.prefix}-subnet-1"
  vpc                      = ibm_is_vpc.vpc.id
  resource_group           = module.resource_group.resource_group_id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  public_gateway           = ibm_is_public_gateway.gateway.id
}

########################################################################################################################
# OCP VPC cluster (single zone)
########################################################################################################################

locals {
  cluster_vpc_subnets = {
    default = [
      {
        id         = ibm_is_subnet.subnet_zone_1.id
        cidr_block = ibm_is_subnet.subnet_zone_1.ipv4_cidr_block
        zone       = ibm_is_subnet.subnet_zone_1.zone
      }
    ]
  }

  worker_pools = [
    {
      subnet_prefix    = "default"
      pool_name        = "default" # ibm_container_vpc_cluster automatically names default pool "default" (See https://github.com/IBM-Cloud/terraform-provider-ibm/issues/2849)
      machine_type     = "bx2.4x16"
      workers_per_zone = 2 # minimum of 2 is allowed when using single zone
      operating_system = "REDHAT_8_64"
    }
  ]
}

locals {
  cluster_name = "${var.prefix}-cluster"
}

module "ocp_base" {
  source                              = "terraform-ibm-modules/base-ocp-vpc/ibm"
  version                             = "3.54.0"
  resource_group_id                   = module.resource_group.resource_group_id
  region                              = var.region
  tags                                = var.resource_tags
  cluster_name                        = local.cluster_name
  force_delete_storage                = true
  vpc_id                              = ibm_is_vpc.vpc.id
  vpc_subnets                         = local.cluster_vpc_subnets
  worker_pools                        = local.worker_pools
  access_tags                         = []
  disable_outbound_traffic_protection = false
}

##############################################################################
# COS instance
##############################################################################

module "cos" {
  source                 = "terraform-ibm-modules/cos/ibm"
  version                = "8.21.25"
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
  version = "8.21.25"
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

module "cloud_logs" {
  source            = "terraform-ibm-modules/cloud-logs/ibm"
  version           = "1.6.0"
  resource_group_id = module.ocp_base.resource_group_id
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
  logs_agent_namespace = "ibm-observe"
  logs_agent_name      = "logs-agent"
}

module "trusted_profile" {
  source                      = "terraform-ibm-modules/trusted-profile/ibm"
  version                     = "2.3.1"
  trusted_profile_name        = "${var.prefix}-profile"
  trusted_profile_description = "Logs agent Trusted Profile"
  # As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agent and routers sending logs.
  trusted_profile_policies = [{
    roles = ["Sender"]
    resources = [{
      service = "logs"
    }]
  }]
  # Set up fine-grained authorization for `logs-agent` running in ROKS cluster in `ibm-observe` namespace.
  trusted_profile_links = [{
    cr_type = "ROKS_SA"
    links = [{
      crn       = module.ocp_base.cluster_crn
      namespace = local.logs_agent_namespace
      name      = local.logs_agent_name
    }]
    }
  ]
}
