##############################################################################
# Outputs
##############################################################################


##############################################################################
#  Cloud automation for Logs Agent- Next Steps URLs outputs
##############################################################################

output "next_steps_text" {
  value       = "Your Logs Instance Environment is ready."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Go to Logs Instance Dashboard" 
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://dashboard.${local.region}.logs.cloud.ibm.com/${local.cloud_logs_instance_id}/#/dashboard"
  description = "Primary URL"
}

output "next_step_secondary_label" {
  value       = "Learn more about IBM Cloud logging"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-about#agent-about-ov"
  description = "Secondary URL"
}

##############################################################################
