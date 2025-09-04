# Terraform IBM Logs agent module

[![Graduated (Supported)](https://img.shields.io/badge/Status-Graduated%20(Supported)-brightgreen)](https://terraform-ibm-modules.github.io/documentation/#/badge-status)
[![pre-commit](https://img.shields.io/badge/pre--commit-enabled-brightgreen?logo=pre-commit&logoColor=white)](https://github.com/pre-commit/pre-commit)
[![latest release](https://img.shields.io/github/v/release/terraform-ibm-modules/terraform-ibm-logs-agent?logo=GitHub&sort=semver)](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/releases/latest)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://renovatebot.com/)
[![semantic-release](https://img.shields.io/badge/%20%20%F0%9F%93%A6%F0%9F%9A%80-semantic--release-e10079.svg)](https://github.com/semantic-release/semantic-release)

This module deploys the following logs agent to an IBM Cloud Red Hat OpenShift Container Platform or Kubernetes cluster:

- [Logs agent](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-about)

<!-- Below content is automatically populated via pre-commit hook -->
<!-- BEGIN OVERVIEW HOOK -->
## Overview
* [terraform-ibm-logs-agent](#terraform-ibm-logs-agent)
* [Examples](./examples)
    * [Logs agent on Kubernetes using CSE ingress endpoint with an apikey](./examples/logs-agent-iks)
    * [Logs agent on OCP using VPE ingress endpoint with a Trusted Profile](./examples/logs-agent-ocp)
* [Contributing](#contributing)
<!-- END OVERVIEW HOOK -->

## terraform-ibm-logs-agent

### Usage

```hcl
# ############################################################################
# Init cluster config for helm
# ############################################################################

data "ibm_container_cluster_config" "cluster_config" {
  cluster_name_id = "xxxxxxxxx" # replace with cluster ID or name
}

# ############################################################################
# Config providers
# ############################################################################

provider "ibm" {
  ibmcloud_api_key = "xxxxxxxxxxxx"  # pragma: allowlist secret
}

provider "helm" {
  kubernetes {
    host                   = data.ibm_container_cluster_config.cluster_config.host
    token                  = data.ibm_container_cluster_config.cluster_config.token
    cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
  }
  # IBM Cloud credentials are required to authenticate to the helm repo
  registry {
    url      = "oci://icr.io/ibm/observe/logs-agent-helm"
    username = "iamapikey"
    password = "xxxxxxxxxxxx"  # pragma: allowlist secret
  }
}

provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config.host
  token                  = data.ibm_container_cluster_config.cluster_config.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
}

# ############################################################################
# Install Logs Agent
# ############################################################################

module "logs_agent_module" {
  source                        = "terraform-ibm-modules/logs-agent/ibm"
  version                       = "X.Y.Z" # replace with actual version of module to consume
  cluster_id                    = "xxxxxxx" # replace with ID of the cluster
  cluster_resource_group_id     = "xxxxxxx" # replace with ID of the cluster resource group
  logs_agent_trusted_profile_id = "XXXXXXXX" # replace with ID of the trusted profile to use for authentication
  cloud_logs_ingress_endpoint   = "<cloud-logs-instance-guid>.ingress.us-south.logs.cloud.ibm.com"
  cloud_logs_ingress_port       = 443
}
```

### Required IAM access policies
You need the following permissions to run this module.

- Service
    - **Resource group only**
        - `Viewer` access on the specific resource group
    - **Kubernetes** service
        - `Viewer` platform access
        - `Manager` service access

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | >= 2.15.0, <3.0.0 |
| <a name="requirement_ibm"></a> [ibm](#requirement\_ibm) | >= 1.80.2, <2.0.0 |

### Modules

No modules.

### Resources

| Name | Type |
|------|------|
| [helm_release.logs_agent](https://registry.terraform.io/providers/hashicorp/helm/latest/docs/resources/release) | resource |
| [ibm_container_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster) | data source |
| [ibm_container_cluster_config.cluster_config](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_cluster_config) | data source |
| [ibm_container_vpc_cluster.cluster](https://registry.terraform.io/providers/ibm-cloud/ibm/latest/docs/data-sources/container_vpc_cluster) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cloud_logs_ingress_endpoint"></a> [cloud\_logs\_ingress\_endpoint](#input\_cloud\_logs\_ingress\_endpoint) | The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress. | `string` | n/a | yes |
| <a name="input_cloud_logs_ingress_port"></a> [cloud\_logs\_ingress\_port](#input\_cloud\_logs\_ingress\_port) | The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs. | `number` | `3443` | no |
| <a name="input_cluster_config_endpoint_type"></a> [cluster\_config\_endpoint\_type](#input\_cluster\_config\_endpoint\_type) | The type of endpoint to use for the cluster config access: `default`, `private`, `vpe`, or `link`. The `default` value uses the default endpoint of the cluster. | `string` | `"default"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The ID of the cluster to deploy the agent. | `string` | n/a | yes |
| <a name="input_cluster_resource_group_id"></a> [cluster\_resource\_group\_id](#input\_cluster\_resource\_group\_id) | The resource group ID of the cluster. | `string` | n/a | yes |
| <a name="input_enable_annotations"></a> [enable\_annotations](#input\_enable\_annotations) | Set to true to include pod annotations in log records. Default annotations such as pod IP address and container ID, along with any custom annotations on the pod, will be included. This can help filter logs based on pod annotations in Cloud Logs. | `bool` | `false` | no |
| <a name="input_enable_multiline"></a> [enable\_multiline](#input\_enable\_multiline) | Enable or disable multiline log support. [Learn more](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-multiline) | `bool` | `false` | no |
| <a name="input_is_vpc_cluster"></a> [is\_vpc\_cluster](#input\_is\_vpc\_cluster) | Specify true if the target cluster for the agent is a VPC cluster, false if it is a classic cluster. | `bool` | `true` | no |
| <a name="input_log_filters"></a> [log\_filters](#input\_log\_filters) | List of additional filters to be applied on logs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/blob/main/solutions/fully-configurable/DA-types.md#configuring-log-filters). | `any` | `[]` | no |
| <a name="input_logs_agent_additional_metadata"></a> [logs\_agent\_additional\_metadata](#input\_logs\_agent\_additional\_metadata) | The list of additional metadata fields to add to the routed logs. | <pre>list(object({<br/>    key   = optional(string)<br/>    value = optional(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_logs_agent_chart"></a> [logs\_agent\_chart](#input\_logs\_agent\_chart) | The name of the Helm chart to deploy. | `string` | `"logs-agent-helm"` | no |
| <a name="input_logs_agent_chart_location"></a> [logs\_agent\_chart\_location](#input\_logs\_agent\_chart\_location) | The location of the Logs agent helm chart. | `string` | `"oci://icr.io/ibm/observe"` | no |
| <a name="input_logs_agent_chart_version"></a> [logs\_agent\_chart\_version](#input\_logs\_agent\_chart\_version) | The version of the Helm chart to deploy. | `string` | `"1.6.1"` | no |
| <a name="input_logs_agent_enable_scc"></a> [logs\_agent\_enable\_scc](#input\_logs\_agent\_enable\_scc) | Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster. | `bool` | `true` | no |
| <a name="input_logs_agent_exclude_log_source_paths"></a> [logs\_agent\_exclude\_log\_source\_paths](#input\_logs\_agent\_exclude\_log\_source\_paths) | The list of log sources to exclude. Specify the paths that the Logs agent ignores. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_iam_api_key"></a> [logs\_agent\_iam\_api\_key](#input\_logs\_agent\_iam\_api\_key) | The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`. | `string` | `null` | no |
| <a name="input_logs_agent_iam_environment"></a> [logs\_agent\_iam\_environment](#input\_logs\_agent\_iam\_environment) | IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`. `Production` specifies the public endpoint & `PrivateProduction` specifies the private endpoint. | `string` | `"PrivateProduction"` | no |
| <a name="input_logs_agent_iam_mode"></a> [logs\_agent\_iam\_mode](#input\_logs\_agent\_iam\_mode) | IAM authentication mode: `TrustedProfile` or `IAMAPIKey`. | `string` | `"TrustedProfile"` | no |
| <a name="input_logs_agent_image_version"></a> [logs\_agent\_image\_version](#input\_logs\_agent\_image\_version) | The version of the Logs agent image to deploy. | `string` | `"1.6.1@sha256:0265b85c698e74dfd9e21ad0332a430a3b398c4f0e590dad314c43b3cd796bce"` | no |
| <a name="input_logs_agent_init_image_version"></a> [logs\_agent\_init\_image\_version](#input\_logs\_agent\_init\_image\_version) | The version of the Logs agent init container image to deploy. | `string` | `"1.6.1@sha256:d2c1bb5a97c0d8950d3dfee016cec4347a6cfa8a43123d9c2eecbdee70500f8b"` | no |
| <a name="input_logs_agent_log_source_namespaces"></a> [logs\_agent\_log\_source\_namespaces](#input\_logs\_agent\_log\_source\_namespaces) | The list of namespaces from which logs should be forwarded by agent. If namespaces are not listed, logs from all namespaces will be sent. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_name"></a> [logs\_agent\_name](#input\_logs\_agent\_name) | The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster. | `string` | `"logs-agent"` | no |
| <a name="input_logs_agent_namespace"></a> [logs\_agent\_namespace](#input\_logs\_agent\_namespace) | The namespace where the Logs agent is deployed. The default value is `ibm-observe`. | `string` | `"ibm-observe"` | no |
| <a name="input_logs_agent_resources"></a> [logs\_agent\_resources](#input\_logs\_agent\_resources) | The resources configuration for cpu/memory/storage. [Learn More](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-helm-template-clusters#agent-helm-template-clusters-chart-options-resources) | <pre>object({<br/>    limits = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>    requests = object({<br/>      cpu    = string<br/>      memory = string<br/>    })<br/>  })</pre> | <pre>{<br/>  "limits": {<br/>    "cpu": "500m",<br/>    "memory": "3Gi"<br/>  },<br/>  "requests": {<br/>    "cpu": "100m",<br/>    "memory": "1Gi"<br/>  }<br/>}</pre> | no |
| <a name="input_logs_agent_selected_log_source_paths"></a> [logs\_agent\_selected\_log\_source\_paths](#input\_logs\_agent\_selected\_log\_source\_paths) | The list of specific log sources paths. Logs will only be collected from the specified log source paths. If no paths are specified, it will send logs from `/var/log/containers`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_system_logs"></a> [logs\_agent\_system\_logs](#input\_logs\_agent\_system\_logs) | The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`. | `list(string)` | `[]` | no |
| <a name="input_logs_agent_tolerations"></a> [logs\_agent\_tolerations](#input\_logs\_agent\_tolerations) | List of tolerations to apply to Logs agent. The default value means a pod will run on every node. | <pre>list(object({<br/>    key               = optional(string)<br/>    operator          = optional(string)<br/>    value             = optional(string)<br/>    effect            = optional(string)<br/>    tolerationSeconds = optional(number)<br/>  }))</pre> | <pre>[<br/>  {<br/>    "operator": "Exists"<br/>  }<br/>]</pre> | no |
| <a name="input_logs_agent_trusted_profile_id"></a> [logs\_agent\_trusted\_profile\_id](#input\_logs\_agent\_trusted\_profile\_id) | The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role. | `string` | `null` | no |
| <a name="input_max_unavailable"></a> [max\_unavailable](#input\_max\_unavailable) | The maximum number of pods that can be unavailable during a DaemonSet rolling update. Accepts absolute number or percentage (e.g., '1' or '10%'). | `string` | `"1"` | no |
| <a name="input_wait_till"></a> [wait\_till](#input\_wait\_till) | To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal` | `string` | `"Normal"` | no |
| <a name="input_wait_till_timeout"></a> [wait\_till\_timeout](#input\_wait\_till\_timeout) | Timeout for wait\_till in minutes. | `number` | `90` | no |

### Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


<!-- Leave this section as is so that your module has a link to local development environment set up steps for contributors to follow -->
## Contributing

You can report issues and request features for this module in GitHub issues in the module repo. See [Report an issue or request a feature](https://github.com/terraform-ibm-modules/.github/blob/main/.github/SUPPORT.md).

To set up your local development environment, see [Local development setup](https://terraform-ibm-modules.github.io/documentation/#/local-dev-setup) in the project documentation.
