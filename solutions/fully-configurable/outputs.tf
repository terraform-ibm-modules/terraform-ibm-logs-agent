##############################################################################
# Outputs
##############################################################################


##############################################################################
#  Cloud automation for Logs Agent- Next Steps URLs outputs
##############################################################################

output "next_steps_text" {
  value       = "Your logs agent is ready to send logs to the instance."
  description = "Next steps text"
}

output "next_step_primary_label" {
  value       = "Go to Cloud Logs dashboard" 
  description = "Primary label"
}

output "next_step_primary_url" {
  value       = "https://dashboard.${local.region}.logs.cloud.ibm.com/${local.cloud_logs_instance_id}/#/dashboard"
  description = "Primary URL"
}

output "next_step_secondary_label" {
  value       = "About the logging agent"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-agent-about"
  description = "Secondary URL"
}

##############################################################################
