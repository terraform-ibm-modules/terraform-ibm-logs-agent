// Tests in this file are NOT run in the PR pipeline. They are run in the continuous testing pipeline along with the ones in pr_test.go
package test

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const terraformDirLogsAgentROKS = "examples/logs-agent-ocp"

func TestRunAgentVpcOcp(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "logs-agent-roks", terraformDirLogsAgentROKS)

	// Keep costs down by using the cloud_pak entitlement
	options.TerraformVars["ocp_entitlement"] = "cloud_pak"

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, options.Region, resourceGroup)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}
