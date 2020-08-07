# Terraform module Kubernetes application

This is a module that deploys an opinionated kubernetes application, consisting of a Deployment and its associated resources (service, service account, hpa, ingress).

The goal is to provide a "Helm like" terraform module, allowing simple k8s deployments with no need to reinvent the wheel or duplicate the code too much.

[![maintained by dataroots](https://img.shields.io/badge/maintained%20by-dataroots-%2300b189)](https://dataroots.io)
[![Terraform 0.12](https://img.shields.io/badge/terraform-0.12-%23623CE4)](https://www.terraform.io)
[![Terraform Registry](https://img.shields.io/badge/terraform-registry-%23623CE4)](https://registry.terraform.io/modules/datarootsio/kubernetes-application/module/)
[![tests](https://github.com/datarootsio/terraform-module-kubernetes-application/workflows/tests/badge.svg?branch=master)](https://github.com/datarootsio/terraform-module-kubernetes-application/actions)
[![Go Report Card](https://goreportcard.com/badge/github.com/datarootsio/terraform-module-kubernetes-application)](https://goreportcard.com/report/github.com/datarootsio/terraform-module-kubernetes-application)

## Modules variables considerations

This module is intended to be as generic as possible. As it's not possible to know all the specific values upfront, all variables of this module are of type `any`. This is needed to allow creation of complex maps for the values. Also, kubernetes allows multiple containers per pods, each one with its own values, variables, etc.

All the documentation of this module will show multi-container variables. If your deployment only uses a single container, it is possible to omit the container name and it will still work.

For instance, you can use either this syntax :

```hcl
name = "foo"

namespace = "bar"

image = "test:latest"

args = ["hello"]

ports = {
  "6000" = {
    "protocol" = "UDP"
  }
}
```

or this syntax :

```hcl
name = "foo"

namespace = "bar"

image = { 
  "foobar" = "test:latest"
}

args = { 
  "foobar" = ["hello"] 
}

ports = {
  "foobar" = {
    "6000" = {
      "protocol" = "UDP"
    }
  }
}
```

However, you have to be consistent across variables, you cannot mix styles.

## Requirements

| Name      | Version    |
| --------- | ---------- |
| terraform | ~> 0.12.20 |

## Providers

| Name       | Version |
| ---------- | ------- |
| kubernetes | n/a     |

## Inputs

| Name                                 | Description                                                                                                                                                             | Type                | Default                                                                                                        | Required |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------- | -------------------------------------------------------------------------------------------------------------- | :------: |
| annotations                          | Map of annotations to add on containers.                                                                                                                                | `map(string)`       | `{}`                                                                                                           |    no    |
| args                                 | Arguments to pass to the container                                                                                                                                      | `any`               | `{}`                                                                                                           |    no    |
| command                              | Command that the container will run                                                                                                                                     | `any`               | `{}`                                                                                                           |    no    |
| environment\_variables               | Map of environment variables to inject in containers.                                                                                                                   | `any`               | `{}`                                                                                                           |    no    |
| environment\_variables\_from\_secret | Map of environment variables to inject in containers, from existing secrets.                                                                                            | `any`               | `{}`                                                                                                           |    no    |
| host\_aliases                        | Host aliases to set up in the pod.                                                                                                                                      | `map(list(string))` | `{}`                                                                                                           |    no    |
| hpa                                  | settings for the horizontal pod autoscaler                                                                                                                              | `any`               | <pre>{<br>  "enabled": false,<br>  "max_replicas": 6,<br>  "min_replicas": 2,<br>  "target_cpu": 80<br>}</pre> |    no    |
| image                                | The image to deploy.                                                                                                                                                    | `any`               | n/a                                                                                                            |   yes    |
| image\_pull\_secrets                 | List of image pull secrets to use with the containers                                                                                                                   | `list(string)`      | `[]`                                                                                                           |    no    |
| inject\_linkerd                      | Add the necessary annotations for linkerd injection                                                                                                                     | `bool`              | `false`                                                                                                        |    no    |
| liveness\_probes                     | Map of liveness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#liveness_probe-1   | `any`               | n/a                                                                                                            |   yes    |
| max_surge                            | Maximum number of pods that can be created over the desired number of pods during update.                                                                               | `string`            | `25%`                                                                                                          |    no    |
| max_unavailable                      | Maximum number of pods that can be unavailable during update.                                                                                                           | `string`            | `25%`                                                                                                          |    no    |
| name                                 | The name of the deployment. Will be used for all other resources                                                                                                        | `string`            | n/a                                                                                                            |   yes    |
| namespace                            | The namespace where this deployment will live. Must exists.                                                                                                             | `string`            | n/a                                                                                                            |   yes    |
| node\_affinity                       | Definition of the node affinity. See below                                                                                                                              | `any`               | `{}`                                                                                                           |    no    |
| node\_selector                       | Map of labels and values for node selection                                                                                                                             | `map(string)`       | `{}`                                                                                                           |    no    |
| pod\_affinity                        | Definition of the pod affinity. See below                                                                                                                               | `any`               | `{}`                                                                                                           |    no    |
| pod\_anti\_affinity                  | Definition of the pod anti-affinity. See below                                                                                                                          | `any`               | `{}`                                                                                                           |    no    |
| ports                                | Map of ports to expose, and associated settings.                                                                                                                        | `any`               | `{}`                                                                                                           |    no    |
| readiness\_probes                    | Map of readiness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#readiness_probe-1 | `any`               | n/a                                                                                                            |   yes    |
| replicas                             | Amount of replicas                                                                                                                                                      | `number`            | `1`                                                                                                            |    no    |
| resources\_limits                    | Map of resources limits to assign to the container                                                                                                                      | `map`               | <pre>{<br>  "cpu": "0.2",<br>  "memory": "256Mi"<br>}</pre>                                                    |    no    |
| resources\_requests                  | Map of resources requests to assign to the container                                                                                                                    | `map`               | <pre>{<br>  "cpu": "0.1",<br>  "memory": "128Mi"<br>}</pre>                                                    |    no    |
| name                                 | The strategy to apply. Can be `RollingUpdate` or `Recreate`                                                                                                             | `string`            | `RollingUpdate                                                                                                 |    no    |
| volume\_mounts                       | Map of volumes to mount.                                                                                                                                                | `any`               | `{}`                                                                                                           |    no    |
| volumes\_mounts\_from\_config\_map   | Map of volumes to mount from config maps.                                                                                                                               | `any`               | `{}`                                                                                                           |    no    |
| volumes\_mounts\_from\_secret        | Map of volumes to mount from secrets.                                                                                                                                   | `any`               | `{}`                                                                                                           |    no    |

## Example values

### environment\_variables

You can add an arbitrary number of env vars (key = value) per container. If empty, will be ignored.

```hcl
environment_variables = {
  "container-b" = {
    "FOO" = "bar"
  }
}
```

### environment\_variables\_from\_secret

You can add an arbitrary number of env vars (key = value) per container, referencing __existing__ secrets. If empty, will be ignored.

```hcl
environment_variables_from_secret = {
  "container-a" = {
    "FOO_SECRET" = {
      secret_name = "foo-name"
      secret_key  = "foo-key"
    }
  }
}
```

### image

You need to define the image for each container that will be set in this deployment.

```hcl
image = {
  "container-a" = "foo:bar"
  "container-b" = "foo-2:bar-2"
}
```

### ports

For each container, you can add map of maps. At minima, you need to provide the protocol. Each pair of protocol-port will be used to create a service.
If you add an ingress map, with the format `{"hostname":"path"}`. You can also choose a cert-manager issuer (refer to the issuers present at the namespace level).
You can add annotations, and choose a default set of annotations (currently only traefik is supported)

```hcl
ports = {
  "container-a" = {
    "3000" = {
      "protocol"                    = "TCP"
      "ingress"                     = {
        "foo.example.com": "/"
        "bar.example.com": "/"
      }
      "default_ingress_annotations" = "traefik"
      "cert_manager_issuer"         = "letsencrypt-prod"
      "ingress_annotations" = {
        "foo.annotations.io" = "bar"
      }
    }
    "6000" = {
      "protocol" = "UDP"
    }
  }
  "container-b" = {
    "1000" = {
      "protocol" = "TCP"
    }
  }
}
```

### resources requests/limits

For each container, you can set cpu and memory requests and limits. If not specified, default will be used :

Limits: 0.2 cpu, 256Mi
Requests: 0.1 cpu, 128Mi

```hcl
resources_requests = {
  "container-a" = {
    cpu    = "0.1"
    memory = "128Mi"
  },
  "container-b" = {
    cpu    = "0.1"
    memory = "256Mi"
  }
}

resources_limits = {
  "container-a" = {
    cpu    = "0.2"
    memory = "256Mi"
  },
  "container-b" = {
    cpu    = "0.5"
    memory = "1024Mi"
  }
}
```

### Readiness/Liveness probes

You can define here the readiness and liveness probes (same object configuration) per container.

Type need to be specified as you can only have one type of probe, and then you need the define the values in the block.
Support for HTTP headers is not there yet, will come.

```hcl
readiness_probes = {
  "container-a" = {

    type = "http_get"

    http_get = {
      path = "/nginx_status"
      port = 80
    }

    tcp_socket {
      port = 80
    }

    exec {
      command = "exit 0"
    }

    initial_delay_seconds = 3
    period_seconds        = 3
  }
}
```

### Node affinity

This block allows to define node affinity of the pod. You can see the settings here : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#affinity-1

We cannot pass blocks as is so you have to create a map from it (aka adding the `=` sign)

```hcl
node_affinity = {
  required_during_scheduling_ignored_during_execution = [
    {
      node_selector_term = [
        {
          match_expressions = [
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values = [
              "linux"]
            }
          ]
        }
      ]
    }
  ]
  preferred_during_scheduling_ignored_during_execution = [
    {
      weight = 1
      preference = {
        match_expressions = [
          {
            key      = "kubernetes.io/os"
            operator = "In"
            values   = ["linux"]
          }
        ]
      }
    }
  ]
}
```

### Pod (anti-)affinity

This block allows to define pod (anti-)affinity. You can see the settings here : https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/deployment#pod_affinity

We cannot pass blocks as is so you have to create a map from it (aka adding the `=` sign)

```hcl
pod_affinity = {
  required_during_scheduling_ignored_during_execution = [
    {
      label_selector = {
        match_labels = {
          "foo" = "bar"
        }
        match_expressions = [
          {
            key      = "security"
            operator = "In"
            values   = ["S1"]
          }
        ]
      }
      namespaces   = ["kube-system"]
      topology_key = "failure-domain.beta.kubernetes.io/zone"
    }
  ]
  preferred_during_scheduling_ignored_during_execution = [
    {
      weight = 1
      pod_affinity_term = {
        label_selector = {
          match_labels = {
            "foo" = "bar"
          }
          match_expressions = [
            {
              key      = "security"
              operator = "In"
              values   = ["S1"]
            }
          ]
        }
        namespaces   = ["kube-system"]
        topology_key = "failure-domain.beta.kubernetes.io/zone"
      }
    }
  ]
}
```

### Horizontal pod autoscaler

Allows to enable the horizontal pod autoscaler. Settings are self explanatory.

```hcl
hpa = {
  enabled       = true
  target_cpu    = 50
  target_memory = 70
  min_replicas  = 4
  max_replicas  = 20
}
```

### Annotations

A map of annotations that will be added to the deployment. Will be merged with specific linkerd annotations if you set `inject_linkerd` to `true`.

```hcl
annotations = {
  foo = bar
  bar = baz
}
```

### Host aliases

A map `{string = list(string)}` defining host aliases to set up in the pod.
```hcl
host_aliases = {
  "127.0.0.1"   = ["foo.bar"],
  "127.0.0.128" = ["bar.baz", "baz.qux"]
}
```

## Terraform plan output with the example values


## Example usage

```hcl
module "my_super_application" {
  source    = "datarootsio/kubernetes-application/module"
  version   = "~> 0.1"
  name      = "some-name"
  namespace = kubernetes_namespace.mynamespace.metadata.0.name

  image = {
    "my-image" = "someimage:v1"
  }

  image_pull_secrets = ["my-super-secret"]

  ports = {
    "my-image" = {
      "5000" = {
        "protocol"                    = "TCP"
        "ingress"                     = "foo.example.com"
        "default_ingress_annotations" = "traefik"
        "cert_manager_issuer"         = "letsencrypt-prod"
        "ingress_annotations" = {
          "foo.annotations.io" = "bar"
        }
      }
    }
  }

  hpa = {
    enabled      = true
    target_cpu   = 50
    min_replicas = 4
    max_replicas = 20
  }

  environment_variables_from_secret = {
    "my-image" = {
      "SECRET_URL" = {
        secret_name = kubernetes_secret.my_secret.metadata.0.name
        secret_key  = "secret-url"
      }

      "PASSWORD" = {
        secret_name = kubernetes_secret.my_secret.metadata.0.name
        secret_key  = "password"
      }
    }
  }

  environment_variables = {
    "my-image" = {
      "USERNAME"  = "user"
      "LOG_LEVEL" = "debug"
    }
  }

  readiness_probes = {
    "my-image" = {
      type = "tcp_socket"

      tcp_socket = {
        port = 5000
      }
      initial_delay_seconds = 15
      period_seconds        = 10
    }
  }

  liveness_probes = {
    "my-image" = {
      type = "http_get"

      http_get = {
        path = "/nginx_status"
        port = 80
      }
      initial_delay_seconds = 15
      period_seconds        = 10
    }
  }
}
```

## Resulting plan

```
Terraform will perform the following actions:

  # module.my_super_application.kubernetes_deployment.container will be created
  + resource "kubernetes_deployment" "container" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + labels           = {
              + "app" = "some-name"
            }
          + name             = "some-name"
          + namespace        = "my-namespace"
        }

      + spec {
          + min_ready_seconds         = 0
          + paused                    = false
          + progress_deadline_seconds = 600
          + replicas                  = 1
          + revision_history_limit    = 10

          + selector {
              + match_labels = {
                  + "app" = "some-name"
                }
            }

          + template {
              + metadata {
                  + annotations      = {
                      + "config.linkerd.io/proxy-cpu-limit"      = "0.75"
                      + "config.linkerd.io/proxy-cpu-request"    = "0.2"
                      + "config.linkerd.io/proxy-memory-limit"   = "768Mi"
                      + "config.linkerd.io/proxy-memory-request" = "128Mi"
                    }
                  + generation       = (known after apply)
                  + labels           = {
                      + "app" = "some-name"
                    }
                }

              + spec {
                  + automount_service_account_token  = true
                  + dns_policy                       = "ClusterFirst"
                  + host_ipc                         = false
                  + host_network                     = false
                  + host_pid                         = false
                  + hostname                         = (known after apply)
                  + node_name                        = (known after apply)
                  + restart_policy                   = "Always"
                  + service_account_name             = "some-name"
                  + share_process_namespace          = false
                  + termination_grace_period_seconds = 30

                  + container {
                      + args                     = []
                      + image                    = "someimage:v1"
                      + image_pull_policy        = (known after apply)
                      + name                     = "my-image"
                      + stdin                    = false
                      + stdin_once               = false
                      + termination_message_path = "/dev/termination-log"
                      + tty                      = false

                      + env {
                          + name  = "LOG_LEVEL"
                          + value = "debug"
                        }
                      + env {
                          + name  = "USERNAME"
                          + value = "user"
                        }
                      + env {
                          + name = "PASSWORD"

                          + value_from {

                              + secret_key_ref {
                                  + key  = "password"
                                  + name = "my-secret"
                                }
                            }
                        }
                      + env {
                          + name = "SECRET_URL"

                          + value_from {

                              + secret_key_ref {
                                  + key  = "secret-url"
                                  + name = "my-secret"
                                }
                            }
                        }

                      + liveness_probe {
                          + failure_threshold     = 3
                          + initial_delay_seconds = 15
                          + period_seconds        = 10
                          + success_threshold     = 1
                          + timeout_seconds       = 5

                          + http_get {
                              + path   = "/nginx_status"
                              + port   = "80"
                              + scheme = "HTTP"
                            }
                        }

                      + port {
                          + container_port = 5000
                          + protocol       = "TCP"
                        }

                      + readiness_probe {
                          + failure_threshold     = 3
                          + initial_delay_seconds = 15
                          + period_seconds        = 10
                          + success_threshold     = 1
                          + timeout_seconds       = 5

                          + tcp_socket {
                              + port = "5000"
                            }
                        }

                      + resources {
                          + limits {
                              + cpu    = "0.2"
                              + memory = "256Mi"
                            }

                          + requests {
                              + cpu    = "0.1"
                              + memory = "128Mi"
                            }
                        }

                      + volume_mount {
                          + mount_path        = (known after apply)
                          + mount_propagation = (known after apply)
                          + name              = (known after apply)
                          + read_only         = (known after apply)
                          + sub_path          = (known after apply)
                        }
                    }

                  + image_pull_secrets {
                      + name = (known after apply)
                    }

                  + volume {
                      + name = (known after apply)

                      + config_map {
                          + default_mode = (known after apply)
                          + name         = (known after apply)

                          + items {
                              + key  = (known after apply)
                              + mode = (known after apply)
                              + path = (known after apply)
                            }
                        }

                      + secret {
                          + default_mode = (known after apply)
                          + optional     = (known after apply)
                          + secret_name  = (known after apply)

                          + items {
                              + key  = (known after apply)
                              + mode = (known after apply)
                              + path = (known after apply)
                            }
                        }
                    }
                }
            }
        }
    }

  # module.my_super_application.kubernetes_horizontal_pod_autoscaler.hpa["hpa"] will be created
  + resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
      + id = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + labels           = {
              + "app" = "some-name"
            }
          + name             = "some-name"
          + namespace        = "my-namespace"
        }

      + spec {
          + max_replicas                      = 20
          + min_replicas                      = 4
          + target_cpu_utilization_percentage = 50

          + scale_target_ref {
              + api_version = "apps/v1"
              + kind        = "Deployment"
              + name        = "some-name"
            }
        }
    }

  # module.my_super_application.kubernetes_ingress.ingress["my-image-5000"] will be created
  + resource "kubernetes_ingress" "ingress" {
      + id                     = (known after apply)
      + load_balancer_ingress  = (known after apply)
      + wait_for_load_balancer = false

      + metadata {
          + annotations      = {
              + "cert-manager.io/issuer"      = "letsencrypt-prod"
              + "foo.annotations.io"          = "bar"
              + "kubernetes.io/ingress.class" = "traefik"
            }
          + generation       = (known after apply)
          + name             = "some-name-my-image-5000"
          + namespace        = "my-namespace"
          + resource_version = (known after apply)
          + self_link        = (known after apply)
          + uid              = (known after apply)
        }

      + spec {

          + rule {
              + host = "foo.example.com"

              + http {
                  + path {
                      + backend {
                          + service_name = "some-name"
                          + service_port = "5000"
                        }
                    }
                }
            }

          + tls {
              + hosts       = [
                  + "foo.example.com",
                ]
              + secret_name = "some-name-my-image-5000"
            }
        }
    }

  # module.my_super_application.kubernetes_service.k8s_service will be created
  + resource "kubernetes_service" "k8s_service" {
      + id                    = (known after apply)
      + load_balancer_ingress = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + labels           = {
              + "app" = "some-name"
            }
          + name             = "some-name"
          + namespace        = "my-namespace"
        }

      + spec {
          + cluster_ip                  = (known after apply)
          + external_traffic_policy     = (known after apply)
          + publish_not_ready_addresses = false
          + selector                    = {
              + "app" = "some-name"
            }
          + session_affinity            = "None"
          + type                        = "ClusterIP"

          + port {
              + name        = "tcp-5000"
              + node_port   = (known after apply)
              + port        = 5000
              + protocol    = "TCP"
              + target_port = "5000"
            }
        }
    }

  # module.my_super_application.kubernetes_service_account.serviceaccount will be created
  + resource "kubernetes_service_account" "serviceaccount" {
      + automount_service_account_token = true
      + default_secret_name             = (known after apply)
      + id                              = (known after apply)

      + metadata {
          + generation       = (known after apply)
          + labels           = {
              + "app" = "some-name"
            }
          + name             = "some-name"
          + namespace        = "my-namespace"
        }
    }

Plan: 5 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------
```

## Outputs

No output.

## Contributing

Contributions to this repository are very welcome! Found a bug or do you have a suggestion? Please open an issue. Do you know how to fix it? Pull requests are welcome as well! To get you started faster, a Makefile is provided.

Make sure to install [Terraform](https://learn.hashicorp.com/terraform/getting-started/install.html), [Go](https://golang.org/doc/install) (for automated testing) and Make (optional, if you want to use the Makefile) on your computer. Install [tflint](https://github.com/terraform-linters/tflint) to be able to run the linting.

* Setup tools & dependencies: `make tools`
* Format your code: `make fmt`
* Linting: `make lint`
* Run tests: `make test` (or `go test -timeout 2h ./...` without Make)

To run the automated tests, you need to be logged in to a kubernetes cluster. We use [k3s](https://k3s.io/) in the test pipelines.

## License

MIT license. Please see [LICENSE](LICENSE.md) for details.