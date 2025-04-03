# Logs agent on Kubernetes using CSE ingress endpoint with an apikey

An example that shows how to deploy Logs agent in a Kubernetes cluster to send Logs directly to IBM Cloud Logs instance.

The example provisions the following resources:
- A new resource group, if an existing one is not passed in.
- A basic VPC (if `is_vpc_cluster` is true).
- A Kubernetes cluster.
- A Service ID with `Sender` role to `logs` service and an apikey.
- An IBM Cloud Logs instance.
- Logs agent.
