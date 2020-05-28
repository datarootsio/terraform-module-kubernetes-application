package test

import (
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func getDefaultTerraformOptions(t *testing.T) (string, *terraform.Options, error) {

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "..", ".")

	namespace := "test-namespace-" + strings.ToLower(random.UniqueId())

	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         map[string]interface{}{},
		RetryableTerraformErrors: map[string]string{
			".*429.*": "Failed to create notebooks due to rate limiting",
			".*does not have any associated worker environments.*:":        "Databricks API was not ready for requests",
			".*we are currently experiencing high demand in this region.*": "Azure service at capacity",
			".*connection reset by peer.*":                                 "Temporary connectivity issue",
		},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Minute,
		NoColor:            true,
		Logger:             logger.TestingT,
	}

	terraformOptions.Vars["name"] = "test-name"
	terraformOptions.Vars["namespace"] = namespace
	terraformOptions.Vars["image"] = map[string]interface{}{"test-container":"training/webapp:latest"}

	return namespace, terraformOptions, nil
}

func TestApplyAndDestroyWithDefaultValues(t *testing.T) {
	t.Parallel()

	namespace, options, err := getDefaultTerraformOptions(t)
	assert.NoError(t, err)

	k8sOptions := k8s.NewKubectlOptions("", "", namespace)
	k8s.CreateNamespace(t, k8sOptions, namespace)
	// website::tag::5::Make sure to delete the namespace at the end of the test
	defer k8s.DeleteNamespace(t, k8sOptions, namespace)

	kubeResourcePath := "./resources.yml"
	defer k8s.KubectlDelete(t, k8sOptions, kubeResourcePath)
	k8s.KubectlApply(t, k8sOptions, kubeResourcePath)

	options.Vars["ports"] = map[string]interface{}{
	    "test-container": map[string]interface{}{
	        "5000": map[string]interface{}{
	            "protocol":"TCP",
	        },
	    },
	}

	options.Vars["readiness_probes"] = map[string]interface{}{
        "test-container": map[string]interface{}{
            "tcp_socket": map[string]interface{}{
                "port":5000,
            },
            "type":"tcp_socket",
        },
	}

    options.Vars["liveness_probes"] = map[string]interface{}{
        "test-container": map[string]interface{}{
            "tcp_socket": map[string]interface{}{
                "port":5000,
            },
            "type":"tcp_socket",
        },
	}


	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)
}
