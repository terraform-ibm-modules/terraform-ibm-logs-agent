variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud API key."
  sensitive   = true
}

##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the agent in."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "cluster_config_endpoint_type" {
  description = "Specify the type of endpoint to use to access the cluster configuration. Possible values: `default`, `private`, `vpe`, `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "private"
  nullable    = false # use default if null is passed in
}

variable "is_vpc_cluster" {
  type        = bool
  description = "Specify true if the target cluster for the DA is a VPC cluster, false if it is classic cluster."
  default     = true
}

variable "wait_till" {
  description = "Specify the stage when Terraform should mark the cluster resource creation as completed. Supported values: `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady`, `Normal`."
  type        = string
  default     = "Normal"
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

##############################################################################
# Logs Agent variables
##############################################################################

variable "chart" {
  description = "The name of the Helm chart to deploy."
  type        = string
  default     = "logs-agent-helm" # Replace with the actual chart name if different
  nullable    = false
}

variable "chart_repository" {
  description = "The repository URL for the Helm chart."
  type        = string
  default     = "oci://icr.io/ibm/observe" # Replace with the actual repository URL if different
  nullable    = false
}

variable "chart_version" {
  description = "The version of the Sysdig Helm chart to deploy."
  type        = string
  default     = "1.5.1" # datasource: icr.io/ibm/observe/logs-agent-helm
}

variable "logs_agent_name" {
  description = "The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logs-agent"
  nullable    = false
}

variable "logs_agent_namespace" {
  type        = string
  description = "The namespace where the Logs agent is deployed. The default value is `ibm-agent`."
  default     = "ibm-agent"
  nullable    = false
}

variable "logs_agent_trusted_profile_id" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role. Must provide a value for `logs_agent_iam_api_key` if `logs_agent_trusted_profile_id` is null."
  default     = null
}

variable "logs_agent_iam_api_key" {
  type        = string
  description = "The IBM Cloud API key for the Logs agent to authenticate and communicate with the IBM Cloud Logs. It is required if `logs_agent_iam_mode` is set to `IAMAPIKey`."
  sensitive   = true
  default     = null
  validation {
    condition     = !(var.logs_agent_iam_mode == "IAMAPIKey" && var.logs_agent_iam_api_key == null)
    error_message = "The `logs_agent_iam_api_key` is required when `logs_agent_iam_mode` is set to `IAMAPIKey`."
  }
}

variable "logs_agent_tolerations" {
  description = "List of tolerations to apply to Logs agent. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/tree/main/solutions/fully-configurable/DA-types.md)."
  type = list(object({
    key               = optional(string)
    operator          = optional(string)
    value             = optional(string)
    effect            = optional(string)
    tolerationSeconds = optional(number)
  }))
  default = [{
    operator = "Exists"
  }]
}

variable "logs_agent_resources" {
  description = "The resources configuration for cpu/memory/storage. Learn more [here](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-helm-template-clusters#agent-helm-template-clusters-chart-options-resources) and [here](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/tree/main/solutions/fully-configurable/DA-types.md)."
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  default = {
    limits = {
      cpu    = "500m"
      memory = "3Gi"
    }
    requests = {
      cpu    = "100m"
      memory = "1Gi"
    }
  }
}

variable "logs_agent_additional_log_source_paths" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/logger-agent-ds-*.log`."
  default     = []
  nullable    = false
}

variable "logs_agent_exclude_log_source_paths" {
  type        = list(string)
  description = "The list of log sources to exclude. Specify the paths that the Logs agent ignores."
  default     = []
  nullable    = false
}

variable "logs_agent_selected_log_source_paths" {
  type        = list(string)
  description = "The list of specific log sources paths. Logs will only be collected from the specified log source paths."
  default     = []
  nullable    = false
}

variable "logs_agent_log_source_namespaces" {
  type        = list(string)
  description = "The list of namespaces from which logs should be forwarded by agent. When specified logs from only these namespaces will be sent by the agent."
  default     = []
  nullable    = false
}

variable "logs_agent_iam_mode" {
  type        = string
  default     = "TrustedProfile"
  description = "IAM authentication mode: `TrustedProfile` or `IAMAPIKey`."
  validation {
    error_message = "The IAM mode can only be `TrustedProfile` or `IAMAPIKey`."
    condition     = contains(["TrustedProfile", "IAMAPIKey"], var.logs_agent_iam_mode)
  }
}

variable "logs_agent_iam_environment" {
  type        = string
  default     = "PrivateProduction"
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
  validation {
    error_message = "The IAM environment can only be `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
    condition     = contains(["Production", "PrivateProduction", "Staging", "PrivateStaging"], var.logs_agent_iam_environment)
  }
}

variable "logs_agent_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/tree/main/solutions/fully-configurable/DA-types.md)."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "is_ocp_cluster" {
  description = "Whether to enable creation of Security Context Constraints in Openshift. When installing on an OpenShift cluster, this setting is mandatory to configure permissions for pods within your cluster."
  type        = bool
  default     = true
}

variable "cloud_logs_ingress_endpoint" {
  description = "The host for IBM Cloud Logs ingestion. Ensure you use the ingress endpoint. See https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-endpoints_ingress."
  type        = string
}

variable "cloud_logs_ingress_port" {
  type        = number
  default     = 3443
  description = "The target port for the IBM Cloud Logs ingestion endpoint. The port must be 443 if you connect by using a VPE gateway, or port 3443 when you connect by using CSEs."
}
