package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestDigitalOceanVPC(t *testing.T) {

	terraformOptions := terraform.WithDefaultRetryableErrors(
		t, &terraform.Options{
			TerraformDir: "../examples/simple/",
			PlanFilePath: "test.tfplan",
			Lock: true,
		})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndPlanAndShow(t, terraformOptions)
	output := terraform.OutputAll(t, terraformOptions)
	assert.NotNil(t, output['droplets'])

}
