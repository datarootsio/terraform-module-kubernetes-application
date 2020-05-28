## Requirements

| Name      | Version |
| --------- | ------- |
| terraform | ~> 0.12 |

## Providers

| Name       | Version |
| ---------- | ------- |
| kubernetes | n/a     |

## Inputs

| Name                                 | Description                                                                                                                                                             | Type     | Default                                                                                                        | Required |
| ------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | -------------------------------------------------------------------------------------------------------------- | :------: |
| environment\_variables               | Map of environment variables to inject in containers.                                                                                                                   | `any`    | `{}`                                                                                                           |    no    |
| environment\_variables\_from\_secret | Map of environment variables to inject in containers, from existing secrets.                                                                                            | `any`    | `{}`                                                                                                           |    no    |
| hpa                                  | settings for the horizontal pod autoscaler                                                                                                                              | `map`    | <pre>{<br>  "enabled": false,<br>  "max_replicas": 6,<br>  "min_replicas": 2,<br>  "target_cpu": 80<br>}</pre> |    no    |
| image                                | The image to deploy.                                                                                                                                                    | `map`    | n/a                                                                                                            |   yes    |
| image\_pull\_secrets                 | Map of image pull secrets to use with the containers                                                                                                                    | `map`    | `{}`                                                                                                           |    no    |
| liveness\_probes                     | Map of liveness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#liveness_probe-1   | `map`    | `{}`                                                                                                           |    no    |
| name                                 | The name of the deployment. Will be used for all other resources                                                                                                        | `string` | n/a                                                                                                            |   yes    |
| namespace                            | The namespace where this deployment will live. Must exists.                                                                                                             | `string` | n/a                                                                                                            |   yes    |
| ports                                | Map of ports to expose, and associated settings.                                                                                                                        | `any`    | `{}`                                                                                                           |    no    |
| readiness\_probes                    | Map of readiness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#readiness_probe-1 | `map`    | `{}`                                                                                                           |    no    |
| resources\_limits                    | Map of resources limits to assign to the container                                                                                                                      | `map`    | <pre>{<br>  "cpu": "0.2",<br>  "memory": "256Mi"<br>}</pre>                                                    |    no    |
| resources\_requests                  | Map of resources requests to assign to the container                                                                                                                    | `map`    | <pre>{<br>  "cpu": "0.1",<br>  "memory": "128Mi"<br>}</pre>                                                    |    no    |

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
If you add an ingress name, the corresponding object will be created. You can also choose a cert-manager issuer (refer to the issuers present at the namespace level).
You can add annotations, and choose a default set of annotations (currently only traefik is supported)

```hcl
ports = {
  "container-a" = {
    "3000" = {
      "protocol"                    = "TCP"
      "ingress"                     = "foo.example.com"
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

### Horizontal pod autoscaler

Allows to enable the horizontal pod autoscaler. Settings are self explanatory.

```hcl
hpa = {
  enabled      = true
  target_cpu   = 50
  min_replicas = 4
  max_replicas = 20
}
```

## Terraform plan output with the example values


## Example usage

```hcl
module "traefik_forward_auth_deployment" {
  source    = "datarootsio/kubernetes-application/module"
  version   = "~> 0.1"
  name      = "traefik-forward-auth"
  namespace = kubernetes_namespace.traefik.metadata.0.name

  image = {
    "traefik-forward-auth" = "thomseddon/traefik-forward-auth:2"
  }

  ports = {
    "traefik-forward-auth" = {
      "4181" = {
        "protocol" = "TCP"
      }
    }
  }

  environment_variables_from_secret = {
    "traefik-forward-auth" = {
      "PROVIDERS_OIDC_CLIENT_ID" = {
        secret_name = kubernetes_secret.traefik_forward_auth.metadata.0.name
        secret_key  = "clientId"
      }

      "PROVIDERS_OIDC_CLIENT_SECRET" = {
        secret_name = kubernetes_secret.traefik_forward_auth.metadata.0.name
        secret_key  = "clientSecret"
      }

      "SECRET" = {
        secret_name = kubernetes_secret.traefik_forward_auth.metadata.0.name
        secret_key  = "secretCookie"
      }
    }
  }

  environment_variables = {
    "traefik-forward-auth" = {
      "DEFAULT_PROVIDER"          = "oidc"
      "LOG_LEVEL"                 = "debug"
      "INSECURE_COOKIE"           = "true"
      "PROVIDERS_OIDC_ISSUER_URL" = "https://sts.windows.net/${data.azurerm_client_config.current.tenant_id}/"
    }
  }

  readiness_probes = {
    "traefik-forward-auth" = {
      type = "tcp_socket"
      tcp_socket = {
        port = 4181
      }
      initial_delay_seconds = 15
      period_seconds        = 10
    }
  }

  liveness_probes = {
    "traefik-forward-auth" = {
      type = "tcp_socket"
      tcp_socket = {
        port = 4181
      }
      initial_delay_seconds = 15
      period_seconds        = 10
    }
  }
}
```

## Outputs

No output.

