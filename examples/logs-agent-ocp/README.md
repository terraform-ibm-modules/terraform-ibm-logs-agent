# Logs agent on OCP using VPE ingress endpoint with a Trusted Profile

<!-- BEGIN SCHEMATICS DEPLOY HOOK -->
<p>
  <a href="https://cloud.ibm.com/schematics/workspaces/create?workspace_name=logs-agent-logs-agent-ocp-example&repository=https://github.com/terraform-ibm-modules/terraform-ibm-logs-agent/tree/main/examples/logs-agent-ocp">
    <img src="https://img.shields.io/badge/Deploy%20with%20IBM%20Cloud%20Schematics-0f62fe?style=flat&logo=ibm&logoColor=white&labelColor=0f62fe" alt="Deploy with IBM Cloud Schematics">
  </a><br>
  ℹ️ Ctrl/Cmd+Click or right-click on the Schematics deploy button to open in a new tab.
</p>
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
