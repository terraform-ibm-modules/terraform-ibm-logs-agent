# Logs agent on OCP using VPE ingress endpoint with a Trusted Profile

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=logs-agent-logs-agent-ocp-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/tree/main/examples/logs-agent-ocp"><img src="https://img.shields.io/badge/Deploy%20with IBM%20Cloud%20Schematics-0f62fe?logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics" style="height: 16px; vertical-align: text-bottom;"></a>
<!-- END SCHEMATICS DEPLOY HOOK -->


An example that shows how to deploy Logs Routing agent in an Red Hat OpenShift container platform cluster to send Logs directly to IBM Cloud Logs instance respectively.

The example provisions the following resources:

- A new resource group, if an existing one is not passed in.
- A basic VPC.
- A Red Hat OpenShift Container Platform VPC cluster.
- A Trusted Profile with `Sender` role to `logs` service.
- An IBM Cloud Logs instance.
- A Virtual Private Endpoint for Cloud Logs.
- Logs agent.

<!-- BEGIN SCHEMATICS DEPLOY TIP HOOK -->
:exclamation: Ctrl/Cmd+Click or right-click to open deploy button in a new tab
<!-- END SCHEMATICS DEPLOY TIP HOOK -->
