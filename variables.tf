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
  default     = "oci://icr.io/ibm-observe" # Public registry - no authentication required
  nullable    = false
}

variable "logs_agent_chart_version" {
  description = "The version of the Helm chart to deploy."
  type        = string
  default     = "1.7.1" # datasource: icr.io/ibm-observe/logs-agent-helm
  nullable    = false
}

variable "logs_agent_init_image_version" {
  description = "The version of the Logs agent init container image to deploy."
  type        = string
  default     = "1.7.1@sha256:6cb1dfe206b4c0f739c7459930719577ef3f1ef3eed022f5590c52785410c042" # datasource: icr.io/ibm/observe/logs-router-agent-init
  nullable    = false
}

variable "logs_agent_image_version" {
  description = "The version of the Logs agent image to deploy."
  type        = string
  default     = "1.7.1@sha256:868a425f2e3cb7bbef609acc4af75cc4dd53e9a455e90fee1d1abc505512c518" # datasource: icr.io/ibm/observe/logs-router-agent
  nullable    = false
  validation {
    condition     = split("@", var.logs_agent_image_version)[0] == split("@", var.logs_agent_init_image_version)[0]
    error_message = "The image tags for `logs_agent_init_image_version` and `logs_agent_image_version` should be same."
  }
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

variable "logs_agent_multi_process_workers" {
  type        = number
  default     = 4
  description = "Specifies the number of multi-process workers to launch. Each worker runs in a separate process, enabling agent to utilize multiple features designed for multi-process operation."
  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.logs_agent_multi_process_workers))
    error_message = "logs_agent_multi_process_workers must be a positive integer (e.g., '1')."
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

variable "enable_kubernetes_filter" {
  description = "Whether to enable the Kubernetes filter in logs-agent. When true, log records are enriched using the Kubernetes API with full metadata such as pod name, container name, namespace, labels, and annotations. When false, Kubernetes API enrichment is skipped and a Lua filter is used to extract limited metadata (e.g. pod name and namespace) from log tags only."
  type        = bool
  default     = true
}

variable "enable_annotations" {
  description = "Set to true to include pod annotations in log records. Default annotations such as pod IP address and container ID, along with any custom annotations on the pod, will be included. This can help filter logs based on pod annotations in Cloud Logs."
  type        = bool
  default     = false

  validation {
    condition     = !(var.enable_annotations && !var.enable_kubernetes_filter)
    error_message = "'enable_annotations' requires 'enable_kubernetes_filter' to be true, as annotations are enriched via the Kubernetes API."
  }
}

variable "max_unavailable" {
  type        = string
  description = "The maximum number of pods that can be unavailable during a DaemonSet rolling update. Accepts absolute number or percentage (e.g., '1' or '10%')."
  default     = "1"
  nullable    = false
  validation {
    condition     = can(regex("^[1-9]\\d*(?:%)?$", var.max_unavailable))
    error_message = "max_unavailable must be a positive integer (e.g., '1') or a percentage (e.g., '10%')"
  }
}


variable "log_filters" {

  # variable type is any because filters schema is not fixed and there are many filters each having its unique fields.
  # logs-agent helm chart expects this variable to be provided in list format even if a single filter is passed.

  description = "List of additional filters to be applied on logs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/blob/main/solutions/fully-configurable/DA-types.md#configuring-log-filters)."
  type        = any
  default     = []
}

variable "additional_outputs" {

  # variable type is any because additionalOutputs schema is not fixed and there are many additionalOutputs each having its unique fields.
  # logs-agent helm chart expects this variable to be provided in list format even if a single additional output is passed.

  description = "Use this input to replace the default additional outputs. [Learn more](https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/blob/main/solutions/fully-configurable/DA-types.md#configuring-additional-outputs)."
  type        = any
  default     = []
  nullable    = false
}

variable "output_match_regex" {
  type        = string
  description = "This is an optional field that defines a regular expression pattern to match against incoming record tags. Use this variable to selectively send records based on their tag values. Supports full regex syntax for complex matching patterns."
  default     = null
}

variable "storage_name" {
  type        = string
  description = "The custom name for the fluent cache that stores data streams and chunks, as well as the database file that tracks processed files and their states, helping prevent multiple logs-agents from using the same cache and database. If no value is passed, the storage name is set to `fluent-bit`."
  default     = null
}

variable "install_required_binaries" {
  type        = bool
  default     = true
  description = "When set to true, a script will run to check if `kubectl` exist on the runtime and if not attempt to download it from the public internet and install it to /tmp. Set to false to skip running this script."
  nullable    = false
}
