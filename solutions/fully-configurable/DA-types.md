# Configuring Logs Agent Tolerations

When you deploy the IBM Logs agent using the `terraform-ibm-logs-agent` module, you can configure the tolerations that the agent applies to its pods by using the `logs_agent_tolerations` variable. This variable allows you to specify tolerations for scheduling the logs agent pods on nodes with specific taints.

### Options for `logs_agent_tolerations`
- `key` (optional): The taint key that the toleration applies to.
- `operator` (optional): The operator to use for the toleration. Valid values are `Exists` and `Equal`.
- `value` (optional): The value to match for the taint key.
- `effect` (optional): The effect of the taint to tolerate. Valid values are `NoSchedule`, `PreferNoSchedule`, and `NoExecute`.
- `tolerationSeconds` (optional): The duration (in seconds) for which the toleration is valid when the `effect` is `NoExecute`.

### Example `logs_agent_tolerations` Usage

To configure tolerations for the logs agent, you can set the `logs_agent_tolerations` variable as follows:

```hcl
logs_agent_tolerations = [
  {
    key      = "example-key"
    operator = "Equal"
    value    = "example-value"
    effect   = "NoSchedule"
  },
  {
    operator = "Exists"
  }
]
```

In this example:
- The first toleration applies to nodes with a taint key of `example-key` and a value of `example-value`, with the `NoSchedule` effect.
- The second toleration applies to any taint key, regardless of value, with the `Exists` operator.

### What It Does

The `logs_agent_tolerations` variable is used to configure the tolerations for the logs agent pods. This allows the agent to run on nodes with specific taints. The configuration is passed to the Helm chart during deployment, ensuring that the logs agent pods are scheduled according to the specified tolerations.

===================================================================

# Configuring Logs Agent Additional Metadata

When you deploy the IBM logs agent using the `terraform-ibm-logs-agent` module, you can configure additional metadata fields to be added to the routed logs by using the `logs_agent_additional_metadata` variable. This variable allows you to specify key-value pairs of metadata that will be included in the logs.

### Options for `logs_agent_additional_metadata`
- `key` (optional): The metadata key to add to the logs.
- `value` (optional): The metadata value to associate with the key.

### Example `logs_agent_additional_metadata` Usage

To configure additional metadata for the logs agent, you can set the `logs_agent_additional_metadata` variable as follows:

```hcl
logs_agent_additional_metadata = [
  {
    key   = "environment"
    value = "production"
  },
  {
    key   = "team"
    value = "devops"
  }
]
```

In this example:
- The first metadata entry adds a key `environment` with the value `production` to the logs.
- The second metadata entry adds a key `team` with the value `devops` to the logs.

### What It Does

The `logs_agent_additional_metadata` variable is used to configure additional metadata fields that are added to the logs routed by the logs agent. This allows you to include custom metadata in the logs for better categorization or identification. The configuration is passed to the Helm chart during deployment, ensuring that the specified metadata is included in the logs.

===================================================================

# Configuring Logs Agent Resources

When you deploy the IBM Logs agent using the `terraform-ibm-logs-agent` module, you can configure the resource requests and limits for the logs agent pods by using the `logs_agent_resources` variable. This variable allows you to specify the CPU and memory resources allocated to the logs agent. [Learn More](https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-helm-template-clusters#agent-helm-template-clusters-chart-options-resources).

### Options for `logs_agent_resources`
- `requests` (optional): Specifies the minimum amount of resources required. Includes:
  - `cpu`: The amount of CPU requested (e.g., `100m` for 0.1 CPU).
  - `memory`: The amount of memory requested (e.g., `128Mi` for 128 MiB).
- `limits` (optional): Specifies the maximum amount of resources allowed. Includes:
  - `cpu`: The maximum amount of CPU allowed.
  - `memory`: The maximum amount of memory allowed.

### Example `logs_agent_resources` Usage

To configure resource requests and limits for the logs agent, you can set the `logs_agent_resources` variable as follows:

```hcl
logs_agent_resources = {
  requests = {
    cpu    = "100m"
    memory = "128Mi"
  }
  limits = {
    cpu    = "500m"
    memory = "256Mi"
  }
}
```

In this example:
- The `requests` section specifies that the logs agent requires at least `100m` CPU and `128Mi` memory to run.
- The `limits` section specifies that the logs agent can use up to `500m` CPU and `256Mi` memory.

### What It Does

The `logs_agent_resources` variable is used to configure the resource requests and limits for the logs agent pods. This ensures that the logs agent has sufficient resources to operate efficiently while preventing it from consuming excessive resources on the node. The configuration is passed to the Helm chart during deployment, ensuring that the specified resource constraints are applied.
