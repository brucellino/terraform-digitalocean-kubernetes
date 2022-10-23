package test

import (
	"strconv"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestInitAndValidate(t *testing.T) {
	retryableTerraformErrors := map[string]string {
		".*Can not delete VPC with members.*": "Out of synch project",
	}
	terraformOptions := terraform.WithDefaultRetryableErrors(
		t, &terraform.Options{
			TerraformDir: "../examples/simple/",
			PlanFilePath: "test.tfplan",
			Lock: true,
			MaxRetries: 2,
			RetryableTerraformErrors: retryableTerraformErrors,
	})

	defer func () {
		_, err := terraform.DestroyE(t, terraformOptions)
		if err != nil {
			terraform.Destroy(t, terraformOptions)
		}
	}()


	// defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndValidateE(t, terraformOptions)
}

func TestDigitalOceanVPC(t *testing.T) {

	terraformOptions := terraform.WithDefaultRetryableErrors(
		t, &terraform.Options{
			TerraformDir: "../examples/simple/",
			PlanFilePath: "test.tfplan",
			Lock: true,
		})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndPlanE(t, terraformOptions)
	terraform.InitAndApplyE(t, terraformOptions)
	droplets := terraform.Output(t, terraformOptions, "droplets")
	n, err := strconv.ParseInt(droplets, 10, 0)
	assert.Nil(t, err)
	assert.LessOrEqual(t, n, 15)

}
