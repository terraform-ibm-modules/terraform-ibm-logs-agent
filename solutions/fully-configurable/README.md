# Cloud automation for Logs Agent

This architecture deploys the following monitoring agent on a Red Hat OpenShift cluster:

* Cloud Monitoring agent

## Before you begin

* Make sure that the Cluster is deployed.

* Make sure that the Cloud Monitoring instance is deployed.

![monitoring-agent-deployable-architecture](../../reference-architecture/deployable-architecture-logs-agent.svg)

**NB:** This solution is not intended to be called by one or more other modules since it contains a provider configurations, meaning it is not compatible with the `for_each`, `count`, and `depends_on` arguments. For more information see [Providers Within Modules](https://developer.hashicorp.com/terraform/language/modules/develop/providers)
