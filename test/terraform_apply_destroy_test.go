package test

import (
	"strings"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
)

func getDefaultTerraformOptions(t *testing.T, suffix string) (string, *terraform.Options, error) {

	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "..", ".")

	namespace := "test-ns-" + suffix + "-" + strings.ToLower(random.UniqueId())

	terraformOptions := &terraform.Options{
		TerraformDir:       tempTestFolder,
		Vars:               map[string]interface{}{},
		MaxRetries:         5,
		TimeBetweenRetries: 5 * time.Minute,
		NoColor:            true,
		Logger:             logger.TestingT,
	}

	terraformOptions.Vars["name"] = "test-name"
	terraformOptions.Vars["namespace"] = namespace

	return namespace, terraformOptions, nil
}

func TestApplyAndDestroyWithDefaultValues(t *testing.T) {
	t.Parallel()

	namespace, options, err := getDefaultTerraformOptions(t, "single-cnt-with-map")
	assert.NoError(t, err)

	k8sOptions := k8s.NewKubectlOptions("", "", namespace)
	k8s.CreateNamespace(t, k8sOptions, namespace)
	// website::tag::5::Make sure to delete the namespace at the end of the test
	defer k8s.DeleteNamespace(t, k8sOptions, namespace)

	kubeResourcePath := "./resources.yml"
	defer k8s.KubectlDelete(t, k8sOptions, kubeResourcePath)
	k8s.KubectlApply(t, k8sOptions, kubeResourcePath)

	options.Vars["image"] = map[string]interface{}{"test-container": "training/webapp:latest"}
	options.Vars["replicas"] = 2
	options.Vars["max_surge"] = "3"
	options.Vars["max_unavailable"] = "0"

	options.Vars["annotations"] = map[string]interface{}{"foo": "bar"}

	options.Vars["ports"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"5000": map[string]interface{}{
				"protocol": "TCP",
			},
		},
	}

	options.Vars["readiness_probes"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"tcp_socket": map[string]interface{}{
				"port": 5000,
			},
			"type": "tcp_socket",
		},
	}

	options.Vars["liveness_probes"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"tcp_socket": map[string]interface{}{
				"port": 5000,
			},
			"type": "tcp_socket",
		},
	}

	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)

	pods := k8s.ListPods(t, k8sOptions, metav1.ListOptions{LabelSelector: "app=test-name"})

	pod := pods[0]
	container := pod.Spec.Containers[0]

	assert.Equal(t, len(pods), 2)
	assert.Equal(t, "training/webapp:latest", container.Image)
	assert.NotContains(t, pod.ObjectMeta.Annotations, "linkerd.io/inject")
	assert.Contains(t, pod.ObjectMeta.Annotations, "foo")
	assert.Equal(t, "bar", pod.ObjectMeta.Annotations["foo"])
}

func TestApplyAndDestroyWithSingleContainer(t *testing.T) {
	t.Parallel()

	namespace, options, err := getDefaultTerraformOptions(t, "sgl-cnt-without-map")
	assert.NoError(t, err)

	k8sOptions := k8s.NewKubectlOptions("", "", namespace)
	k8s.CreateNamespace(t, k8sOptions, namespace)
	// website::tag::5::Make sure to delete the namespace at the end of the test
	defer k8s.DeleteNamespace(t, k8sOptions, namespace)

	kubeResourcePath := "./resources.yml"
	defer k8s.KubectlDelete(t, k8sOptions, kubeResourcePath)
	k8s.KubectlApply(t, k8sOptions, kubeResourcePath)

	options.Vars["image"] = "\"training/webapp:latest\""

	options.Vars["inject_linkerd"] = true
	options.Vars["strategy"] = "Recreate"

	options.Vars["ports"] = map[string]interface{}{
		"5000": map[string]interface{}{
			"protocol": "TCP",
		},
	}

	options.Vars["readiness_probes"] = map[string]interface{}{
		"tcp_socket": map[string]interface{}{
			"port": 5000,
		},
		"type": "tcp_socket",
	}

	options.Vars["annotations"] = map[string]interface{}{
		"foo": "bar",
		"bar": "baz",
	}

	options.Vars["image_pull_secrets"] = []string{"'my-secret'", "'my-other-secret'"}

	options.Vars["host_aliases"] = map[string]interface{}{
		"127.0.0.1": []string{"foo.bar", "bar.baz"},
	}

	options.Vars["node_affinity"] = map[string]interface{}{
		"preferred_during_scheduling_ignored_during_execution": []interface{}{
			map[string]interface{}{
				"weight": 10,
				"preference": map[string]interface{}{
					"match_expressions": []interface{}{
						map[string]interface{}{
							"key":      "kubernetes.io/os",
							"operator": "In",
							"values":   []string{"linux"},
						},
						map[string]interface{}{
							"key":      "beta.kubernetes.io/instance-type",
							"operator": "In",
							"values":   []string{"k3s"},
						},
					},
				},
			},
			map[string]interface{}{
				"weight": 100,
				"preference": map[string]interface{}{
					"match_expressions": []interface{}{
						map[string]interface{}{
							"key":      "beta.kubernetes.io/arch",
							"operator": "In",
							"values":   []string{"amd64"},
						},
					},
				},
			},
		},
		"required_during_scheduling_ignored_during_execution": []interface{}{
			map[string]interface{}{
				"node_selector_term": []interface{}{
					map[string]interface{}{
						"match_expressions": []interface{}{
							map[string]interface{}{
								"key":      "kubernetes.io/os",
								"operator": "In",
								"values":   []string{"linux"},
							},
						},
					},
				},
			},
		},
	}

	options.Vars["liveness_probes"] = map[string]interface{}{
		"tcp_socket": map[string]interface{}{
			"port": 5000,
		},
		"type": "tcp_socket",
	}

	options.Vars["environment_variables_from_secret"] = map[string]interface{}{
		"SUPER_SECRET": map[string]interface{}{
			"secret_name": "test-secret",
			"secret_key":  "username",
		},
	}

	options.Vars["environment_variables"] = map[string]interface{}{
		"SUPER_VARIABLE": "super-value",
	}

	options.Vars["volumes_mounts_from_config_map"] = map[string]interface{}{
		"test-configmap": map[string]interface{}{
			"mount_path": "/data/myconfigmap",
			"sub_path":   "",
		},
	}

	options.Vars["volumes_mounts_from_secret"] = map[string]interface{}{
		"test-secret": map[string]interface{}{
			"mount_path": "/data/mysecret",
			"sub_path":   "",
		},
	}

	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)

	pods := k8s.ListPods(t, k8sOptions, metav1.ListOptions{LabelSelector: "app=test-name"})

	pod := pods[0]
	container := pod.Spec.Containers[0]

	assert.Equal(t, len(pods), 1)
	assert.Equal(t, "training/webapp:latest", container.Image)
	assert.Contains(t, pod.ObjectMeta.Annotations, "linkerd.io/inject")
	assert.Contains(t, pod.ObjectMeta.Annotations, "foo")
	assert.Contains(t, pod.ObjectMeta.Annotations, "bar")
	assert.Equal(t, "bar", pod.ObjectMeta.Annotations["foo"])
	assert.Equal(t, "kubernetes.io/os", pod.Spec.Affinity.NodeAffinity.RequiredDuringSchedulingIgnoredDuringExecution.NodeSelectorTerms[0].MatchExpressions[0].Key)
	assert.EqualValues(t, "127.0.0.1", pod.Spec.HostAliases[0].IP)
	assert.EqualValues(t, []string{"foo.bar", "bar.baz"}, pod.Spec.HostAliases[0].Hostnames)
	assert.Equal(t, "enabled", pod.ObjectMeta.Annotations["linkerd.io/inject"])
}

func TestApplyAndDestroyWithPlentyOfValues(t *testing.T) {
	t.Parallel()

	namespace, options, err := getDefaultTerraformOptions(t, "multi-cnt-plenty-vals")
	assert.NoError(t, err)

	k8sOptions := k8s.NewKubectlOptions("", "", namespace)
	k8s.CreateNamespace(t, k8sOptions, namespace)
	// website::tag::5::Make sure to delete the namespace at the end of the test
	defer k8s.DeleteNamespace(t, k8sOptions, namespace)

	kubeResourcePath := "./resources.yml"
	defer k8s.KubectlDelete(t, k8sOptions, kubeResourcePath)
	k8s.KubectlApply(t, k8sOptions, kubeResourcePath)

	options.Vars["image"] = map[string]interface{}{
		"test-container":   "training/webapp:latest",
		"test-container-2": "nginxdemos/hello",
	}

	options.Vars["ports"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"5000": map[string]interface{}{
				"protocol": "TCP",
			},
			"6000": map[string]interface{}{
				"protocol": "TCP",
				"ingress": map[string]interface{}{
					"foo.example.com": "/",
					"bar.example.com": "/",
				},
				"default_ingress_annotations": "traefik",
				"cert_manager_issuer":         "letsencrypt-prod",
				"path":                        "/api/v1",
				"ingress_annotations": map[string]interface{}{
					"foo.annotations.io": "bar",
				},
			},
		},
		"test-container-2": map[string]interface{}{
			"80": map[string]interface{}{
				"protocol": "TCP",
			},
		},
	}

	options.Vars["environment_variables_from_secret"] = map[string]interface{}{
		"test-container-2": map[string]interface{}{
			"SUPER_SECRET": map[string]interface{}{
				"secret_name": "test-secret",
				"secret_key":  "username",
			},
		},
	}

	options.Vars["environment_variables"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"SUPER_VARIABLE": "super-value",
		},
	}

	options.Vars["readiness_probes"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"tcp_socket": map[string]interface{}{
				"port": 5000,
			},
			"type": "tcp_socket",
		},
		"test-container-2": map[string]interface{}{
			"tcp_socket": map[string]interface{}{
				"port": 80,
			},
			"type": "tcp_socket",
		},
	}

	options.Vars["liveness_probes"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"tcp_socket": map[string]interface{}{
				"port": 5000,
			},
			"type": "tcp_socket",
		},
		"test-container-2": map[string]interface{}{
			"tcp_socket": map[string]interface{}{
				"port": 80,
			},
			"type": "tcp_socket",
		},
	}

	options.Vars["volumes_mounts_from_config_map"] = map[string]interface{}{
		"test-container": map[string]interface{}{
			"test-configmap": map[string]interface{}{
				"mount_path": "/data/myconfigmap",
				"sub_path":   "",
			},
		},
	}

	options.Vars["volumes_mounts_from_secret"] = map[string]interface{}{
		"test-container-2": map[string]interface{}{
			"test-secret": map[string]interface{}{
				"mount_path": "/data/mysecret",
				"sub_path":   "",
			},
		},
	}

	options.Vars["hpa"] = map[string]interface{}{
		"enabled":       true,
		"target_cpu":    50,
		"target_memory": 60,
		"min_replicas":  1,
		"max_replicas":  2,
	}

	options.Vars["node_selector"] = map[string]interface{}{
		"kubernetes.io/os": "linux",
	}

	options.Vars["pod_anti_affinity"] = map[string]interface{}{
		"preferred_during_scheduling_ignored_during_execution": []interface{}{
			map[string]interface{}{
				"weight": 10,
				"pod_affinity_term": map[string]interface{}{
					"namespaces":   []string{namespace},
					"topology_key": "kubernetes.io/hostname",
					"label_selector": map[string]interface{}{
						"match_expressions": []interface{}{
							map[string]interface{}{
								"key":      "node-role.kubernetes.io/master",
								"operator": "In",
								"values":   []string{"true"},
							},
						},
					},
				},
			},
		},
		"required_during_scheduling_ignored_during_execution": []interface{}{
			map[string]interface{}{
				"namespaces":   []string{namespace},
				"topology_key": "kubernetes.io/hostname",
				"label_selector": map[string]interface{}{
					"match_expressions": []interface{}{
						map[string]interface{}{
							"key":      "node-role.kubernetes.io/master",
							"operator": "In",
							"values":   []string{"true"},
						},
					},
				},
			},
		},
	}

	defer terraform.Destroy(t, options)
	_, err = terraform.InitAndApplyE(t, options)
	assert.NoError(t, err)
}
