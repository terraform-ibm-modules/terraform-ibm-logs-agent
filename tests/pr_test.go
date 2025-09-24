// Tests in this file are run in the PR pipeline
package test

import (
	"fmt"
	"os"
	"strings"
	"testing"

	"math/rand/v2"

	"github.com/IBM/go-sdk-core/core"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const resourceGroup = "geretain-test-observability-agents"
const fullyConfigurableSolutionDir = "solutions/fully-configurable"
const fullyConfigurableSolutionKubeconfigDir = "solutions/fully-configurable/kubeconfig"
const terraformDirLogsAgentIKS = "examples/logs-agent-iks"

var IgnoreUpdates = []string{
	"module.logs_agent.helm_release.logs_agent",
}

var sharedInfoSvc *cloudinfo.CloudInfoService

var validRegions = []string{
	"au-syd",
	// Temporarily disabling europe regions due to IKS error
	//"eu-gb",
	//"eu-de",
	//"eu-es",
	"us-south",
}

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, terraformDir string) *testhelper.TestOptions {

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDir,
		Prefix:        prefix,
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
		CloudInfoService: sharedInfoSvc,
	})

	return options
}

func TestFullyConfigurableSolution(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.IntN(len(validRegions))]

	// ------------------------------------------------------------------------------------------------------
	// Deploy OCP Cluster and Logs instance since it is needed to deploy Logs Agent
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("ocp-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]any{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp resources (OCP and Logs Instance) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "logs-agent",
			TarIncludePatterns: []string{
				"*.tf",
				"kubeconfig/*.*",
				"scripts/*.*",
				fullyConfigurableSolutionDir + "/*.*",
				fullyConfigurableSolutionKubeconfigDir + "/*.*",
			},
			IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
				List: IgnoreUpdates,
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         fullyConfigurableSolutionDir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "workload_cluster_id"), DataType: "string"},
			{Name: "logs_agent_trusted_profile_id", Value: terraform.Output(t, existingTerraformOptions, "trusted_profile_id"), DataType: "string"},
			{Name: "cloud_logs_ingress_endpoint", Value: terraform.Output(t, existingTerraformOptions, "cloud_logs_ingress_private_endpoint"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
		}

		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestFullyConfigurableUpgradeSolution(t *testing.T) {
	t.Parallel()

	var region = validRegions[rand.IntN(len(validRegions))]

	// ------------------------------------------------------------------------------------------------------
	// Deploy OCP Cluster and Observability instances since it is needed to deploy Logs Agent
	// ------------------------------------------------------------------------------------------------------

	prefix := fmt.Sprintf("ocp-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]any{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp resources (OCP and Logs Instances) failed")
	} else {

		options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
			Testing: t,
			Prefix:  "logs-agent",
			TarIncludePatterns: []string{
				"*.tf",
				"kubeconfig/*.*",
				"scripts/*.*",
				fullyConfigurableSolutionDir + "/*.*",
				fullyConfigurableSolutionKubeconfigDir + "/*.*",
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         fullyConfigurableSolutionDir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
				List: IgnoreUpdates,
			},
		})

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "ibmcloud_api_key", Value: options.RequiredEnvironmentVars["TF_VAR_ibmcloud_api_key"], DataType: "string", Secure: true},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "cluster_id", Value: terraform.Output(t, existingTerraformOptions, "workload_cluster_id"), DataType: "string"},
			{Name: "logs_agent_trusted_profile_id", Value: terraform.Output(t, existingTerraformOptions, "trusted_profile_id"), DataType: "string"},
			{Name: "cloud_logs_ingress_endpoint", Value: terraform.Output(t, existingTerraformOptions, "cloud_logs_ingress_private_endpoint"), DataType: "string"},
			{Name: "cluster_resource_group_id", Value: terraform.Output(t, existingTerraformOptions, "cluster_resource_group_id"), DataType: "string"},
		}

		err := options.RunSchematicUpgradeTest()
		assert.Nil(t, err, "This should not have errored")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunAgentClassicKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "logs-agent-iks", terraformDirLogsAgentIKS)
	options.TerraformVars["is_vpc_cluster"] = false
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "logs-agent-iks", terraformDirLogsAgentIKS)
	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestAgentDefaultConfiguration(t *testing.T) {

	/*
		Skipping this test because auto-approve is not working as expected in projects
		Config gets stuck in approved state and doesn't move to deployment
		https://github.ibm.com/epx/projects/issues/4814
	*/
	t.Skip("Skipping because of projects issue")
	t.Parallel()

	options := testaddons.TestAddonsOptionsDefault(&testaddons.TestAddonOptions{
		Testing:   t,
		Prefix:    "la-def",
		QuietMode: false,
	})

	options.AddonConfig = cloudinfo.NewAddonConfigTerraform(
		options.Prefix,
		"deploy-arch-ibm-logs-agent",
		"fully-configurable",
		map[string]interface{}{
			"region":                       "eu-de",
			"prefix":                       options.Prefix,
			"secrets_manager_service_plan": "trial",
		},
	)

	/*
		Event notifications is manually disabled in this test because event notifications DA creates kms keys and during undeploy the order of key protect and event notifications
		is not considered by projects as EN is not a direct dependency of VSI DA. So undeploy fails, because
		key protect instance can't be deleted because of active keys created by EN. Hence for now, we don't want to deploy
		EN.

		Issue has been created for projects team. https://github.ibm.com/epx/projects/issues/4750
		Once that is fixed, we can remove the logic to disable EN
	*/
	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		{
			OfferingName:   "deploy-arch-ibm-event-notifications",
			OfferingFlavor: "fully-configurable",
			Enabled:        core.BoolPtr(false), // explicitly disabled
		},
	}
	err := options.RunAddonTest()
	require.NoError(t, err)
}
