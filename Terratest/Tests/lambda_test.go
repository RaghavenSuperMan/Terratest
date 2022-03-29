package test

import (
	// "context"
	"crypto/tls"
	"fmt"
	"github.com/gruntwork-io/terratest/modules/aws"
	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	// "github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	// test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	// "github.com/aws/aws-sdk-go-v2/config"
	"github.com/stretchr/testify/assert"

	// "github.com/stretchr/testify/require"
	// "github.com/aws/aws-sdk-go-v2"
	// "github.com/aws/aws-sdk-go/service/sfn"
	"testing"
	"time"
)

// Function should start with Test
// FIlename should have _test
func TestRaghavtest(t *testing.T) {
	fmt.Printf("Raghav test case started --> ")
	// Used for paralel exe
	t.Parallel()

	// Setup Terraform Config
	terraformOptions := &terraform.Options{
		TerraformDir: "../Infra",
		// If needed to use var files for testing VarFiles:     []string{"tests/simple_test_input.tfvars"},
	}

	// Queue up the eventual destroy, and then create IAC
	fmt.Println("Queing destroy for later --> ")
	defer terraform.Destroy(t, terraformOptions)

	fmt.Println("TF Init & apply strart --> ")
	terraform.InitAndApply(t, terraformOptions)

	fmt.Println("TF Init & apply Completed --> ")
	dns := terraform.Output(t, terraformOptions, "dns")

	fmt.Println("DNS Value from TF Output =>  ", dns)

	// Json payload for Lambda
	type ExampleFunctionPayload struct {
		Ip1 string
		Ip2 string
	}

	req := &ExampleFunctionPayload{
		Ip1: "",
		Ip2: "",
	}

	// DHC Flow POC
	// Lambda
	// Invoke the function, so we can test its output
	// Ref :https://docs.aws.amazon.com/sdk-for-go/v1/developer-guide/lambda-go-example-run-function.html
	response := aws.InvokeFunction(t, "us-east-1", "raghaven_super_man", req)
	fmt.Println("Lambda Response => ", string(response))
	fmt.Println("Lambda Assertion => ")
	assert.NotNil(t, response)

	// DHC Flow POC
	// Step Function
	// Invoke the list step function, so we can test its output
	// Ref : https://pkg.go.dev/github.com/aws/aws-sdk-go-v2/service/sfn#Client.ListExecutions
	// Load config from environment
	// cfg, err := config.LoadDefaultConfig(context.TODO())
	// client := sfn.NewFromConfig(cfg)

	// sf := ListStateMachines(t)
	// fmt.Println("SF Data =>  ", sf)

	time.Sleep(100 * time.Second)
	fmt.Println("Sleep Over.....")
	// Perform an HTTP request on the resource and ensure we get a 200.

	// Console / OL / Web App flow POC
	tlsConfig := tls.Config{}
	statusCode, body := http_helper.HttpGet(t, fmt.Sprintf("http://%s", dns), &tlsConfig)

	fmt.Println("Assertion statusCode =>  ", statusCode)
	fmt.Println("Assertion body =>  ", body)

	assert.Equal(t, 200, statusCode)
	assert.NotNil(t, body)

}
