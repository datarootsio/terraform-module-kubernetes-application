resource "kubernetes_deployment" "container" {
  metadata {
    name      = var.name
    namespace = var.namespace

    labels = {
      app = var.name
    }
  }

  spec {
    selector {
      match_labels = {
        app = var.name
      }
    }

    strategy {
      type = var.strategy
      dynamic "rolling_update" {
        for_each = var.strategy == "RollingUpdate" ? ["rolling_update"] : []
        content {
          max_surge       = var.max_surge
          max_unavailable = var.max_unavailable
        }
      }
    }

    replicas = var.replicas

    template {
      metadata {
        labels = {
          app = var.name
        }
        annotations = local.annotations
      }

      spec {
        dynamic "host_aliases" {
          for_each = var.host_aliases
          content {
            hostnames = host_aliases.value
            ip        = host_aliases.key
          }
        }

        affinity {
          dynamic "node_affinity" {
            for_each = length(var.node_affinity) > 0 ? ["node_affinity"] : []
            content {
              dynamic "preferred_during_scheduling_ignored_during_execution" {
                for_each = { for v in lookup(var.node_affinity, "preferred_during_scheduling_ignored_during_execution", []) : uuid() => v }
                content {
                  weight = preferred_during_scheduling_ignored_during_execution.value["weight"]
                  preference {
                    dynamic "match_expressions" {
                      for_each = { for v in lookup(preferred_during_scheduling_ignored_during_execution.value["preference"], "match_expressions", []) : uuid() => v }
                      content {
                        key      = match_expressions.value["key"]
                        operator = match_expressions.value["operator"]
                        values   = lookup(match_expressions.value, "values", [])
                      }
                    }
                  }
                }
              }
              dynamic "required_during_scheduling_ignored_during_execution" {
                for_each = { for v in lookup(var.node_affinity, "required_during_scheduling_ignored_during_execution", []) : uuid() => v }
                content {
                  dynamic "node_selector_term" {
                    for_each = { for v in lookup(required_during_scheduling_ignored_during_execution.value, "node_selector_term", []) : uuid() => v }
                    content {
                      dynamic "match_expressions" {
                        for_each = { for v in lookup(node_selector_term.value, "match_expressions", []) : uuid() => v }
                        content {
                          key      = match_expressions.value["key"]
                          operator = match_expressions.value["operator"]
                          values   = lookup(match_expressions.value, "values", [])
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          dynamic "pod_affinity" {
            for_each = length(var.pod_affinity) > 0 ? ["pod_affinity"] : []
            content {
              dynamic "preferred_during_scheduling_ignored_during_execution" {
                for_each = { for v in lookup(var.pod_affinity, "preferred_during_scheduling_ignored_during_execution", []) : uuid() => v }
                content {
                  weight = preferred_during_scheduling_ignored_during_execution.value["weight"]
                  pod_affinity_term {
                    namespaces   = lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"], "namespaces", [])
                    topology_key = lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"], "topology_key", "")
                    label_selector {
                      match_labels = lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"]["label_selector"], "match_labels", {})
                      dynamic "match_expressions" {
                        for_each = { for v in lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"]["label_selector"], "match_expressions", []) : uuid() => v }
                        content {
                          key      = match_expressions.value["key"]
                          operator = match_expressions.value["operator"]
                          values   = lookup(match_expressions.value, "values", [])
                        }
                      }
                    }
                  }
                }
              }
              dynamic "required_during_scheduling_ignored_during_execution" {
                for_each = { for v in lookup(var.pod_affinity, "required_during_scheduling_ignored_during_execution", []) : uuid() => v }
                content {
                  label_selector {
                    match_labels = lookup(required_during_scheduling_ignored_during_execution.value["label_selector"], "match_labels", {})
                    dynamic "match_expressions" {
                      for_each = { for v in lookup(required_during_scheduling_ignored_during_execution.value["label_selector"], "match_expressions", []) : uuid() => v }
                      content {
                        key      = match_expressions.value["key"]
                        operator = match_expressions.value["operator"]
                        values   = lookup(match_expressions.value, "values", [])
                      }
                    }
                  }
                  namespaces   = lookup(required_during_scheduling_ignored_during_execution.value, "namespaces", [])
                  topology_key = lookup(required_during_scheduling_ignored_during_execution.value, "topology_key", "")
                }
              }
            }
          }

          dynamic "pod_anti_affinity" {
            for_each = length(var.pod_anti_affinity) > 0 ? ["pod_anti_affinity"] : []
            content {
              dynamic "preferred_during_scheduling_ignored_during_execution" {
                for_each = { for v in lookup(var.pod_anti_affinity, "preferred_during_scheduling_ignored_during_execution", []) : uuid() => v }
                content {
                  weight = preferred_during_scheduling_ignored_during_execution.value["weight"]
                  pod_affinity_term {
                    namespaces   = lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"], "namespaces", [])
                    topology_key = lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"], "topology_key", "")
                    label_selector {
                      match_labels = lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"]["label_selector"], "match_labels", {})
                      dynamic "match_expressions" {
                        for_each = { for v in lookup(preferred_during_scheduling_ignored_during_execution.value["pod_affinity_term"]["label_selector"], "match_expressions", []) : uuid() => v }
                        content {
                          key      = match_expressions.value["key"]
                          operator = match_expressions.value["operator"]
                          values   = lookup(match_expressions.value, "values", [])
                        }
                      }
                    }
                  }
                }
              }
              dynamic "required_during_scheduling_ignored_during_execution" {
                for_each = { for v in lookup(var.pod_anti_affinity, "required_during_scheduling_ignored_during_execution", []) : uuid() => v }
                content {
                  label_selector {
                    match_labels = lookup(required_during_scheduling_ignored_during_execution.value["label_selector"], "match_labels", {})
                    dynamic "match_expressions" {
                      for_each = { for v in lookup(required_during_scheduling_ignored_during_execution.value["label_selector"], "match_expressions", []) : uuid() => v }
                      content {
                        key      = match_expressions.value["key"]
                        operator = match_expressions.value["operator"]
                        values   = lookup(match_expressions.value, "values", [])
                      }
                    }
                  }
                  namespaces   = lookup(required_during_scheduling_ignored_during_execution.value, "namespaces", [])
                  topology_key = lookup(required_during_scheduling_ignored_during_execution.value, "topology_key", "")
                }
              }
            }
          }

        }

        automount_service_account_token = true

        service_account_name = kubernetes_service_account.serviceaccount.metadata.0.name

        node_selector = var.node_selector

        dynamic "image_pull_secrets" {
          for_each = { for v in var.image_pull_secrets : v => v }
          content {
            name = image_pull_secrets.key
          }
        }

        dynamic "volume" {
          for_each = local.volumes_map
          content {
            name = volume.value
            persistent_volume_claim {
              claim_name = volume.value
            }
          }
        }

        dynamic "volume" {
          for_each = local.volumes_from_config_maps_map
          content {
            name = volume.value
            config_map {
              name = volume.value
            }
          }
        }

        dynamic "volume" {
          for_each = local.volumes_from_secrets_map
          content {
            name = volume.value
            secret {
              secret_name = volume.value
            }
          }
        }

        dynamic "container" {
          for_each = local.image
          content {
            name  = container.key
            image = container.value

            args = lookup(local.args, container.key, [])

            command = lookup(local.command, container.key, [])

            resources {
              limits {
                cpu    = lookup(lookup(local.resources_limits, container.key, {}), "cpu", "0.2")
                memory = lookup(lookup(local.resources_limits, container.key, {}), "memory", "256Mi")
              }
              requests {
                cpu    = lookup(lookup(local.resources_requests, container.key, {}), "cpu", "0.1")
                memory = lookup(lookup(local.resources_requests, container.key, {}), "memory", "128Mi")
              }
            }

            liveness_probe {
              dynamic "http_get" {
                for_each = lookup(lookup(local.liveness_probes, container.key, {}), "type", "") == "http_get" ? ["http_get"] : []
                content {
                  path = local.liveness_probes[container.key]["http_get"]["path"]
                  port = local.liveness_probes[container.key]["http_get"]["port"]
                }
              }

              dynamic "tcp_socket" {
                for_each = lookup(lookup(local.liveness_probes, container.key, {}), "type", "") == "tcp_socket" ? ["tcp_socket"] : []
                content {
                  port = local.liveness_probes[container.key]["tcp_socket"]["port"]
                }
              }

              dynamic "exec" {
                for_each = lookup(lookup(local.liveness_probes, container.key, {}), "type", "") == "exec" ? ["exec"] : []
                content {
                  command = local.liveness_probes[container.key]["exec"]["command"]
                }
              }

              initial_delay_seconds = lookup(lookup(local.liveness_probes, container.key, {}), "initial_delay_seconds", 5)
              timeout_seconds       = lookup(lookup(local.liveness_probes, container.key, {}), "timeout_seconds", 5)
              period_seconds        = lookup(lookup(local.liveness_probes, container.key, {}), "period_seconds", 5)
              failure_threshold     = lookup(lookup(local.liveness_probes, container.key, {}), "failure_threshold", 3)
            }

            readiness_probe {
              dynamic "http_get" {
                for_each = lookup(lookup(local.readiness_probes, container.key, {}), "type", "") == "http_get" ? ["http_get"] : []
                content {
                  path = local.readiness_probes[container.key]["http_get"]["path"]
                  port = local.readiness_probes[container.key]["http_get"]["port"]
                }
              }

              dynamic "tcp_socket" {
                for_each = lookup(lookup(local.readiness_probes, container.key, {}), "type", "") == "tcp_socket" ? ["tcp_socket"] : []
                content {
                  port = local.readiness_probes[container.key]["tcp_socket"]["port"]
                }
              }

              dynamic "exec" {
                for_each = lookup(lookup(local.readiness_probes, container.key, {}), "type", "") == "exec" ? ["exec"] : []
                content {
                  command = local.readiness_probes[container.key]["exec"]["command"]
                }
              }

              initial_delay_seconds = lookup(lookup(local.readiness_probes, container.key, {}), "initial_delay_seconds", 5)
              timeout_seconds       = lookup(lookup(local.readiness_probes, container.key, {}), "timeout_seconds", 5)
              period_seconds        = lookup(lookup(local.readiness_probes, container.key, {}), "period_seconds", 5)
              failure_threshold     = lookup(lookup(local.readiness_probes, container.key, {}), "failure_threshold", 3)
            }

            dynamic "port" {
              for_each = lookup(local.ports, container.key, {})
              content {
                container_port = port.key
                protocol       = port.value["protocol"]
              }
            }

            dynamic "volume_mount" {
              for_each = lookup(local.volume_mounts, container.key, {})
              content {
                name       = volume_mount.key
                read_only  = lookup(volume_mount.value, "read_only", true)
                mount_path = volume_mount.value["mount_path"]
                sub_path   = lookup(volume_mount.value, "sub_path", "")
              }
            }

            dynamic "volume_mount" {
              for_each = lookup(local.volumes_mounts_from_config_map, container.key, {})
              content {
                name       = volume_mount.key
                read_only  = lookup(volume_mount.value, "read_only", true)
                mount_path = volume_mount.value["mount_path"]
                sub_path   = lookup(volume_mount.value, "sub_path", "")
              }
            }

            dynamic "volume_mount" {
              for_each = lookup(local.volumes_mounts_from_secret, container.key, {})
              content {
                name       = volume_mount.key
                read_only  = lookup(volume_mount.value, "read_only", true)
                mount_path = volume_mount.value["mount_path"]
                sub_path   = lookup(volume_mount.value, "sub_path", "")
              }
            }

            dynamic "env" {
              for_each = lookup(local.environment_variables, container.key, {})
              content {
                name  = env.key
                value = env.value
              }
            }

            dynamic "env" {
              for_each = lookup(local.environment_variables_from_secret, container.key, {})
              content {
                name = env.key
                value_from {
                  secret_key_ref {
                    name = env.value["secret_name"]
                    key  = env.value["secret_key"]
                  }
                }
              }
            }
          }
        }

        restart_policy                   = "Always"
        termination_grace_period_seconds = 30
        dns_policy                       = "ClusterFirst"
      }
    }
  }
}
