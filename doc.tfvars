
name = "foo"

namespace = "foo-namespace"

image = {
  "container-a" = "foo:bar"
  "container-b" = "foo-2:bar-2"
}

args = {
  "container-a" = ["foo"]
  "container-b" = ["bar", "foobar"]
}

ports = {
  "container-a" = {
    "3000" = {
      "protocol" = "TCP"
      "ingress" = {
        "foo.example.com" : "/"
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

annotations = {
  "foo" = "bar"
  "bar" = "baz"
}

host_aliases = {
  "127.0.0.1" = ["foo.bar"],
  "8.8.8.8"   = ["bar.baz", "baz.qux"]
}

strategy = "RollingUpdate"

max_surge = "50%"

max_unavailable = "50%"

node_affinity = {
  required_during_scheduling_ignored_during_execution = [
    {
      node_selector_term = [
        {
          match_expressions = [
            {
              key      = "kubernetes.io/os"
              operator = "In"
              values   = ["linux"]
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

pod_anti_affinity = {
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

environment_variables_from_secret = {
  "container-a" = {
    "FOO_SECRET" = {
      secret_name = "foo-name"
      secret_key  = "foo-key"
    }
  }
}

environment_variables = {
  "container-b" = {
    "FOO" = "bar"
  }
}

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

readiness_probes = {
  "container-a" = {

    type = "http_get"

    http_get = {
      path = "/nginx_status"
      port = 80
    }

    initial_delay_seconds = 3
    period_seconds        = 3
  }
}

hpa = {
  enabled      = true
  target_cpu   = 50
  min_replicas = 4
  max_replicas = 20
}

volume_mounts = {
  "container-a" = {
    "volume-a" = {
      read_only  = true
      mount_path = "/mnt/myvolume"
      sub_path   = "mysubpath"
    }
  }
}

volumes_mounts_from_config_map = {
  "container-a" = {
    "config-map-a" = {
      mount_path = "/data/myconfigmap"
      sub_path   = ""
    }
  }
}

volumes_mounts_from_secret = {
  "container-a" = {
    "secret-a" = {
      mount_path = "/data/myconfigmap"
      sub_path   = ""
    }
  }
}

node_selector = {
  "disktype" = "ssd"
}