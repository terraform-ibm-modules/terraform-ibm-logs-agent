##############################################################################
# Cluster variables
##############################################################################

variable "cluster_id" {
  type        = string
  description = "The ID of the cluster to deploy the agent."
}

variable "cluster_resource_group_id" {
  type        = string
  description = "The resource group ID of the cluster."
}

variable "cluster_config_endpoint_type" {
  description = "The type of endpoint to use for the cluster config access: `default`, `private`, `vpe`, or `link`. The `default` value uses the default endpoint of the cluster."
  type        = string
  default     = "default"
  nullable    = false # use default if null is passed in
  validation {
    error_message = "Invalid endpoint type. Valid values are `default`, `private`, `vpe`, or `link`."
    condition     = contains(["default", "private", "vpe", "link"], var.cluster_config_endpoint_type)
  }
}

variable "is_vpc_cluster" {
  description = "Specify true if the target cluster for the agent is a VPC cluster, false if it is a classic cluster."
  type        = bool
  default     = true
}

variable "wait_till" {
  description = "To avoid long wait times when you run your Terraform code, you can specify the stage when you want Terraform to mark the cluster resource creation as completed. Depending on what stage you choose, the cluster creation might not be fully completed and continues to run in the background. However, your Terraform code can continue to run without waiting for the cluster to be fully created. Supported args are `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` and `Normal`"
  type        = string
  default     = "Normal"

  validation {
    error_message = "`wait_till` value must be one of `MasterNodeReady`, `OneWorkerNodeReady`, `IngressReady` or `Normal`."
    condition = contains([
      "MasterNodeReady",
      "OneWorkerNodeReady",
      "IngressReady",
      "Normal"
    ], var.wait_till)
  }
}

variable "wait_till_timeout" {
  description = "Timeout for wait_till in minutes."
  type        = number
  default     = 90
}

##############################################################################
# Logs Agent variables
##############################################################################

variable "logs_agent_chart" {
  description = "The name of the Helm chart to deploy."
  type        = string
  default     = "logs-agent-helm" # Replace with the actual chart name if different
  nullable    = false
}

variable "logs_agent_chart_location" {
  description = "The location of the Logs agent helm chart."
  type        = string
  default     = "oci://icr.io/ibm/observe" # Replace with the actual repository URL if different
  nullable    = false
}

variable "logs_agent_chart_version" {
  description = "The version of the Helm chart to deploy."
  type        = string
  default     = "1.6.1" # datasource: icr.io/ibm/observe/logs-agent-helm
  nullable    = false
}

variable "logs_agent_image_version" {
  description = "The version of the Logs agent image to deploy."
  type        = string
  default     = "1.6.1" # datasource: icr.io/ibm/observe/logs-agent-helm
  nullable    = false
}

variable "logs_agent_name" {
  description = "The name of the Logs agent. The name is used in all Kubernetes and Helm resources in the cluster."
  type        = string
  default     = "logs-agent"
  nullable    = false
}

variable "logs_agent_namespace" {
  type        = string
  description = "The namespace where the Logs agent is deployed. The default value is `ibm-observe`."
  default     = "ibm-observe"
  nullable    = false
}

variable "logs_agent_trusted_profile_id" {
  type        = string
  description = "The IBM Cloud trusted profile ID. Used only when `logs_agent_iam_mode` is set to `TrustedProfile`. The trusted profile must have an IBM Cloud Logs `Sender` role."
  default     = null
  validation {
    condition     = !(var.logs_agent_trusted_profile_id == null && var.logs_agent_iam_mode == "TrustedProfile")
    error_message = "The `logs_agent_trusted_profile_id` is required when `logs_agent_iam_mode` is set to `TrustedProfile`."
  }
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
  description = "List of tolerations to apply to Logs agent. The default value means a pod will run on every node."
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
  description = "The resources configuration for cpu/memory/storage. [Learn More](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-helm-template-clusters#agent-helm-template-clusters-chart-options-resources)"
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

variable "logs_agent_system_logs" {
  type        = list(string)
  description = "The list of additional log sources. By default, the Logs agent collects logs from a single source at `/var/log/containers/*.log`."
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
  description = "The list of specific log sources paths. Logs will only be collected from the specified log source paths. If no paths are specified, it will send logs from `/var/log/containers`."
  default     = []
  nullable    = false
}

variable "logs_agent_log_source_namespaces" {
  type        = list(string)
  description = "The list of namespaces from which logs should be forwarded by agent. If namespaces are not listed, logs from all namespaces will be sent."
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
  description = "IAM authentication Environment: `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`. `Production` specifies the public endpoint & `PrivateProduction` specifies the private endpoint."
  validation {
    error_message = "The IAM environment can only be `Production` or `PrivateProduction` or `Staging` or `PrivateStaging`."
    condition     = contains(["Production", "PrivateProduction", "Staging", "PrivateStaging"], var.logs_agent_iam_environment)
  }
}

variable "logs_agent_additional_metadata" {
  description = "The list of additional metadata fields to add to the routed logs."
  type = list(object({
    key   = optional(string)
    value = optional(string)
  }))
  default = []
}

variable "logs_agent_enable_scc" {
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
  validation {
    error_message = "The Logs Routing supertenant ingestion port can only be `3443` or `443`."
    condition     = contains([3443, 443], var.cloud_logs_ingress_port)
  }
}
variable "enable_multiline" {
  description = "Enable or disable multiline log support. [Learn more](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-multiline)"
  type        = bool
  default     = false
}
