##############################################################################
# Resource Group
##############################################################################

module "resource_group" {
  source  = "terraform-ibm-modules/resource-group/ibm"
  version = "1.4.7"
  # if an existing resource group is not set (null) create a new one using prefix
  resource_group_name          = var.resource_group == null ? "${var.prefix}-resource-group" : null
  existing_resource_group_name = var.resource_group
}

##############################################################################
# Service ID with logs sender role + apikey
##############################################################################

# As a `Sender`, you can send logs to your IBM Cloud Logs service instance - but not query or tail logs. This role is meant to be used by agent and routers sending logs.
module "iam_service_id" {
  source                          = "terraform-ibm-modules/iam-service-id/ibm"
  version                         = "1.2.8"
  iam_service_id_name             = "${var.prefix}-service-id"
  iam_service_id_description      = "Logs Agent service id"
  iam_service_id_apikey_provision = true
  iam_service_policies = {
    logs = {
      roles = ["Sender"]
      resources = [{
        service = "logs"
      }]
    }
  }
}

##############################################################################
# Create VPC and IKS Cluster
##############################################################################

resource "ibm_is_vpc" "example_vpc" {
  count          = var.is_vpc_cluster ? 1 : 0
  name           = "${var.prefix}-vpc"
  resource_group = module.resource_group.resource_group_id
  tags           = var.resource_tags
}

resource "ibm_is_subnet" "testacc_subnet" {
  count                    = var.is_vpc_cluster ? 1 : 0
  name                     = "${var.prefix}-subnet"
  vpc                      = ibm_is_vpc.example_vpc[0].id
  zone                     = "${var.region}-1"
  total_ipv4_address_count = 256
  resource_group           = module.resource_group.resource_group_id
}

# Lookup the current default kube version
data "ibm_container_cluster_versions" "cluster_versions" {}
locals {
  default_version = data.ibm_container_cluster_versions.cluster_versions.default_kube_version
}

resource "ibm_container_vpc_cluster" "cluster" {
  count                = var.is_vpc_cluster ? 1 : 0
  name                 = var.prefix
  vpc_id               = ibm_is_vpc.example_vpc[0].id
  kube_version         = local.default_version
  flavor               = "bx2.4x16"
  worker_count         = "2"
  force_delete_storage = true
  wait_till            = "IngressReady"
  zones {
    subnet_id = ibm_is_subnet.testacc_subnet[0].id
    name      = "${var.region}-1"
  }
  resource_group_id = module.resource_group.resource_group_id
  tags              = var.resource_tags
}

resource "ibm_container_cluster" "cluster" {
  #checkov:skip=CKV2_IBM_7:Public endpoint is required for testing purposes
  count                = var.is_vpc_cluster ? 0 : 1
  name                 = var.prefix
  datacenter           = var.datacenter
  default_pool_size    = 2
  hardware             = "shared"
  kube_version         = local.default_version
  force_delete_storage = true
  machine_type         = "b3c.4x16"
  public_vlan_id       = ibm_network_vlan.public_vlan[0].id
  private_vlan_id      = ibm_network_vlan.private_vlan[0].id
  wait_till            = "Normal"
  resource_group_id    = module.resource_group.resource_group_id
  tags                 = var.resource_tags

  timeouts {
    delete = "2h"
    create = "3h"
  }
}

locals {
  cluster_name_id = var.is_vpc_cluster ? ibm_container_vpc_cluster.cluster[0].id : ibm_container_cluster.cluster[0].id
}

resource "ibm_network_vlan" "public_vlan" {
  count      = var.is_vpc_cluster ? 0 : 1
  datacenter = var.datacenter
  type       = "PUBLIC"
}

resource "ibm_network_vlan" "private_vlan" {
  count      = var.is_vpc_cluster ? 0 : 1
  datacenter = var.datacenter
  type       = "PRIVATE"
}

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id   = local.cluster_name_id
  resource_group_id = module.resource_group.resource_group_id
}

# Sleep to allow RBAC sync on cluster
resource "time_sleep" "wait_operators" {
  depends_on      = [data.ibm_container_cluster_config.cluster_config]
  create_duration = "45s"
}

##############################################################################
# Cloud Logs Instance
##############################################################################

module "cloud_logs" {
  source            = "terraform-ibm-modules/cloud-logs/ibm"
  version           = "1.10.25"
  resource_group_id = module.resource_group.resource_group_id
  plan              = "standard"
  region            = var.region
  instance_name     = "${var.prefix}-cloud-logs"
  resource_tags     = var.resource_tags
}

##############################################################################
# Logs Agent
##############################################################################

module "logs_agent" {
  source                    = "../.."
  depends_on                = [time_sleep.wait_operators]
  cluster_id                = local.cluster_name_id
  is_vpc_cluster            = var.is_vpc_cluster
  cluster_resource_group_id = module.resource_group.resource_group_id
  # Logs Agent
  logs_agent_iam_mode         = "IAMAPIKey"
  logs_agent_iam_api_key      = module.iam_service_id.service_id_apikey
  cloud_logs_ingress_endpoint = module.cloud_logs.ingress_private_endpoint
  cloud_logs_ingress_port     = 3443
  logs_agent_enable_scc       = false # only true for Openshift
  log_filters = [
    {
      name  = "lua"
      match = "*"
      call  = "add_crn_field"
      code  = <<EOL
      -- Enrich records with CRN field
      -- This is just a sample code for showing usage of lua filter
      function add_crn_field(tag, timestamp, record)

          record["logSourceCRN"] = "crn:v1:bluemix:public:postgres:us-south:a/123456::"
          record["saveServiceCopy"] = "true"

          return 2, 0, record
      end
      EOL
    },
    {
      name    = "grep"
      match   = "*"
      exclude = ["message.level debug"]
    }
  ]
}
