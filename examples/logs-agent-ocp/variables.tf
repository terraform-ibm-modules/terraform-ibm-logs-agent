variable "ibmcloud_api_key" {
  type        = string
  description = "The IBM Cloud api token"
  sensitive   = true
}

variable "prefix" {
  type        = string
  description = "A prefix for the name of all resources that are created by this example"
  default     = "logs-agent-ocp"
}

variable "resource_group" {
  type        = string
  description = "An existing resource group name to use for this example. If not specified, a new resource group is created."
  default     = null
}

variable "resource_tags" {
  type        = list(string)
  description = "A list of tags to add to the resources that are created."
  default = [
    {
      name : "logger-icl-output-plugin",
      id : "logs-router-icl-output-plugin-2",
      match : "*",
      retry_limit : "False",
      target_host : "4714f4b5-bb00-4b74-abc5-5f1fb7e9eeb4.ingress.private.eu-gb.logs.cloud.ibm.com",
      target_port : 3443,
      target_path : "/logs/v1/singles",
      authentication_mode : "TrustedProfile",
      iam_environment : "PrivateProduction",
      trusted_profile_id : "Profile-f5ea3d16-d9be-45d3-baa9-27e19b0f4020",
      cr_token_mount_path : "/var/run/secrets/tokens/vault-token",
      logging_level : "info",
      workers : 4,
      "storage.total_limit_size" : "5G",
    },
    {
      name : "logger-icl-output-plugin",
      id : "logs-router-icl-output-plugin-3",
      match : "*",
      retry_limit : "False",
      target_host : "4714f4b5-bb00-4b74-abc5-5f1fb7e9eeb4.ingress.private.eu-gb.logs.cloud.ibm.com",
      target_port : 3443,
      target_path : "/logs/v1/singles",
      authentication_mode : "TrustedProfile",
      iam_environment : "PrivateProduction",
      trusted_profile_id : "Profile-f5ea3d16-d9be-45d3-baa9-27e19b0f4020",
      cr_token_mount_path : "/var/run/secrets/tokens/vault-token",
      logging_level : "info",
      workers : 4,
      "storage.total_limit_size" : "5G",
    }
  ]
}

variable "access_tags" {
  type        = list(string)
  description = "Optional list of access management tags to add to resources that are created"
  default     = []
}

variable "region" {
  type        = string
  description = "The region where the resources are created."
  default     = "au-syd"
}

variable "ocp_version" {
  type        = string
  description = "Version of the OCP cluster to provision"
  default     = null
}

variable "ocp_entitlement" {
  type        = string
  description = "Value that is applied to the entitlements for OCP cluster provisioning"
  default     = null
}
