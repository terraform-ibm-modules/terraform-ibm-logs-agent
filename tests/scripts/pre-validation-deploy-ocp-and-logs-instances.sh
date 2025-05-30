#! /bin/bash

############################################################################################################
## This script is used by the catalog pipeline to deploy the OCP and Monitoring instances,
## which are the prerequisites for the Monitoring Agent DA.
############################################################################################################

set -e

DA_DIR="solutions/fully-configurable"
TERRAFORM_SOURCE_DIR="tests/resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning prerequisite OCP Cluster and Logs Instance.."
  terraform init || exit 1
  # $VALIDATION_APIKEY is available in the catalog runtime
  {
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "prefix=\"ocp-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  cluster_id_var_name="cluster_id"
  cluster_id_value=$(terraform output -state=terraform.tfstate -raw workload_cluster_id)
  cluster_resource_group_id_var_name="cluster_resource_group_id"
  cluster_resource_group_id_value=$(terraform output -state=terraform.tfstate -raw cluster_resource_group_id)
  logs_agent_trusted_profile_id_var_name="logs_agent_trusted_profile_id"
  logs_agent_trusted_profile_id_value=$(terraform output -state=terraform.tfstate -raw trusted_profile_id)
  cloud_logs_ingress_endpoint_var_name="cloud_logs_ingress_endpoint"
  cloud_logs_ingress_endpoint_value=$(terraform output -state=terraform.tfstate -raw cloud_logs_ingress_private_endpoint)

  echo "Appending '${cluster_id_var_name}' '${cluster_resource_group_id_var_name}', '${logs_agent_trusted_profile_id_var_name}', and '${cloud_logs_ingress_endpoint_var_name}' input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg cluster_id_var_name "${cluster_id_var_name}" \
        --arg cluster_id_value "${cluster_id_value}" \
        --arg cluster_resource_group_id_var_name "${cluster_resource_group_id_var_name}" \
        --arg cluster_resource_group_id_value "${cluster_resource_group_id_value}" \
        --arg logs_agent_trusted_profile_id_var_name "${logs_agent_trusted_profile_id_var_name}" \
        --arg logs_agent_trusted_profile_id_value "${logs_agent_trusted_profile_id_value}" \
        --arg cloud_logs_ingress_endpoint_var_name "${cloud_logs_ingress_endpoint_var_name}" \
        --arg cloud_logs_ingress_endpoint_value "${cloud_logs_ingress_endpoint_value}" \
        '. + {($cluster_id_var_name): $cluster_id_value, ($cluster_resource_group_id_var_name): $cluster_resource_group_id_value, ($logs_agent_trusted_profile_id_var_name): $logs_agent_trusted_profile_id_value, ($cloud_logs_ingress_endpoint_var_name): $cloud_logs_ingress_endpoint_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)
