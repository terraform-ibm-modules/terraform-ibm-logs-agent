// Tests in this file are run in the PR pipeline
package test

import (
	"bytes"
	"crypto/rand"
	"fmt"
	"log"
	"math/big"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testaddons"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const resourceGroup = "geretain-test-observability-agents"
const fullyConfigurableSolutionDir = "solutions/fully-configurable"
const fullyConfigurableSolutionKubeconfigDir = "solutions/fully-configurable/kubeconfig"
const terraformDirLogsAgentIKS = "examples/logs-agent-iks"
const terraformVersion = "terraform_v1.12.2" // This should match the version in the ibm_catalog.json
// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}
var IgnoreUpdates = []string{
	"module.logs_agent.helm_release.logs_agent",
	"module.logs_agent.terraform_data.install_required_binaries[0]",
}

var IgnoreDestroys = []string{
	"module.logs_agent.terraform_data.install_required_binaries[0]",
}

var sharedInfoSvc *cloudinfo.CloudInfoService

var validRegions = []string{
	"au-syd",
	"eu-gb",
	"eu-de",
	"eu-es",
	"us-south",
}

// TestMain will be run before any parallel tests, used to set up a shared InfoService object to track region usage
// for multiple tests
func TestMain(m *testing.M) {
	var err error
	sharedInfoSvc, err = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
	if err != nil {
		log.Fatal(err)
	}

	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

// getRandomRegion returns a random region from the validRegions slice using crypto/rand
func getRandomRegion() string {
	n, err := rand.Int(rand.Reader, big.NewInt(int64(len(validRegions))))
	if err != nil {
		panic(fmt.Sprintf("failed to generate random region: %v", err))
	}
	return validRegions[n.Int64()]
}

func validateEnvVariable(t *testing.T, varName string) string {
	val, present := os.LookupEnv(varName)
	require.True(t, present, "%s environment variable not set", varName)
	require.NotEqual(t, "", val, "%s environment variable is empty", varName)
	return val
}

func createContainersApikey(t *testing.T, region string, rg string) {

	err := os.Setenv("IBMCLOUD_API_KEY", validateEnvVariable(t, "TF_VAR_ibmcloud_api_key"))
	require.NoError(t, err, "Failed to set IBMCLOUD_API_KEY environment variable")
	scriptPath := "../common-dev-assets/scripts/iks-api-key-reset/reset_iks_api_key.sh"
	cmd := exec.Command("bash", scriptPath, region, rg)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Execute the command
	if err := cmd.Run(); err != nil {
		log.Fatalf("Failed to execute script: %v\nStderr: %s", err, stderr.String())
	}
	// Print script output
	fmt.Println(stdout.String())
}

func setupOptions(t *testing.T, prefix string, terraformDir string) *testhelper.TestOptions {

	options := testhelper.TestOptionsDefaultWithVars(&testhelper.TestOptions{
		Testing:       t,
		TerraformDir:  terraformDir,
		Prefix:        prefix,
		Region:        getRandomRegion(),
		ResourceGroup: resourceGroup,
		IgnoreUpdates: testhelper.Exemptions{ // Ignore for consistency check
			List: IgnoreUpdates,
		},
		IgnoreDestroys: testhelper.Exemptions{ // Ignore destroy/recreate actions
			List: []string{"module.logs_agent.terraform_data.install_required_binaries[0]"},
		},
		CloudInfoService:           sharedInfoSvc,
		CheckApplyResultForUpgrade: true,
	})

	return options
}

func TestFullyConfigurableSolution(t *testing.T) {
	t.Parallel()

	var region = getRandomRegion()

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
			"prefix":         prefix,
			"region":         region,
			"resource_group": resourceGroup,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, region, resourceGroup)

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
			IgnoreDestroys: testhelper.Exemptions{ // Ignore destroy/recreate actions
				List: IgnoreDestroys,
			},
			ResourceGroup:          resourceGroup,
			TemplateFolder:         fullyConfigurableSolutionDir,
			Tags:                   []string{"test-schematic"},
			DeleteWorkspaceOnFail:  false,
			WaitJobCompleteMinutes: 60,
			Region:                 region,
			TerraformVersion:       terraformVersion,
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

	var region = getRandomRegion()

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
			"prefix":         prefix,
			"region":         region,
			"resource_group": resourceGroup,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, region, resourceGroup)

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
			IgnoreDestroys: testhelper.Exemptions{ // Ignore destroy/recreate actions
				List: IgnoreDestroys,
			},
			TerraformVersion:           terraformVersion,
			CheckApplyResultForUpgrade: true,
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

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, options.Region, resourceGroup)

	output, err := options.RunTestConsistency()
	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestRunAgentVpcKubernetes(t *testing.T) {
	t.Parallel()

	options := setupOptions(t, "logs-agent-iks", terraformDirLogsAgentIKS)
	output, err := options.RunTestConsistency()

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, options.Region, resourceGroup)

	assert.Nil(t, err, "This should not have errored")
	assert.NotNil(t, output, "Expected some output")
}

func TestAgentDefaultConfiguration(t *testing.T) {

	t.Parallel()

	var region = getRandomRegion()

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
			"region":                       region,
			"existing_resource_group_name": resourceGroup,
		},
	)

	options.AddonConfig.Dependencies = []cloudinfo.AddonConfig{
		//	use existing secrets manager instance to help prevent hitting trial instance limit in account
		{
			OfferingName:   "deploy-arch-ibm-secrets-manager",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"existing_secrets_manager_crn":         permanentResources["privateOnlySecMgrCRN"],
				"service_plan":                         "__NULL__", // no plan value needed when using existing SM
				"skip_secrets_manager_iam_auth_policy": true,       // since using an existing Secrets Manager instance, attempting to re-create auth policy can cause conflicts if the policy already exists
				"secret_groups":                        []string{}, // passing empty array for secret groups as default value is creating general group and it will cause conflicts as we are using an existing SM
			},
		},
		// // Disable target / route creation to help prevent hitting quota in account
		{
			OfferingName:   "deploy-arch-ibm-cloud-monitoring",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_metrics_routing_to_cloud_monitoring": false,
			},
		},
		{
			OfferingName:   "deploy-arch-ibm-activity-tracker",
			OfferingFlavor: "fully-configurable",
			Inputs: map[string]interface{}{
				"enable_activity_tracker_event_routing_to_cloud_logs": false,
			},
		},
	}

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	createContainersApikey(t, region, resourceGroup)

	err := options.RunAddonTest()
	require.NoError(t, err)
}
