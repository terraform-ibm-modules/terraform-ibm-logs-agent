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
  value       = "https://dashboard.${element(split(":", var.instance_crn), 5)}.logs.cloud.ibm.com/${element(split(":", var.instance_crn), 7)}"
  description = "Primary URL"
}

output "next_step_secondary_label" {
  value       = "Learn more about IBM Cloud logging"
  description = "Secondary label"
}

output "next_step_secondary_url" {
  value       = "https://cloud.ibm.com/docs/cloud-logs?topic=cloud-logs-getting-started"
  description = "Secondary URL"
}

##############################################################################
