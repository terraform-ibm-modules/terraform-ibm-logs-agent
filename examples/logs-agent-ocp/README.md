# Logs agent on OCP using VPE ingress endpoint with a Trusted Profile

An example that shows how to deploy Logs Routing agent in an Red Hat OpenShift container platform cluster to send Logs directly to IBM Cloud Logs instance respectively.

The example provisions the following resources:

- A new resource group, if an existing one is not passed in.
- A basic VPC.
- A Red Hat OpenShift Container Platform VPC cluster.
- A Trusted Profile with `Sender` role to `logs` service.
- An IBM Cloud Logs instance.
- A Virtual Private Endpoint for Cloud Logs.
- Logs agent.
