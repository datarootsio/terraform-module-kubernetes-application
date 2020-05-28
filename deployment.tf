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

    template {
      metadata {
        labels = {
          app = var.name
        }
        annotations = merge(
          local.linkerd_annotations
        )
      }

      spec {

        automount_service_account_token = true

        service_account_name = kubernetes_service_account.serviceaccount.metadata.0.name

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
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
          for_each = var.image
          content {
            name  = container.key
            image = container.value

            args = lookup(var.args, container.key, [])

            resources {
              limits {
                cpu    = lookup(lookup(var.resources_limits, container.key, {}), "cpu", "0.2")
                memory = lookup(lookup(var.resources_limits, container.key, {}), "memory", "256Mi")
              }
              requests {
                cpu    = lookup(lookup(var.resources_requests, container.key, {}), "cpu", "0.1")
                memory = lookup(lookup(var.resources_requests, container.key, {}), "memory", "128Mi")
              }
            }

            liveness_probe {
              dynamic "http_get" {
                for_each = lookup(lookup(var.liveness_probes, container.key, {}), "type", "") == "http_get" ? ["http_get"] : []
                content {
                  path = var.liveness_probes[container.key]["http_get"]["path"]
                  port = var.liveness_probes[container.key]["http_get"]["port"]
                }
              }

              dynamic "tcp_socket" {
                for_each = lookup(lookup(var.liveness_probes, container.key, {}), "type", "") == "tcp_socket" ? ["tcp_socket"] : []
                content {
                  port = var.liveness_probes[container.key]["tcp_socket"]["port"]
                }
              }

              dynamic "exec" {
                for_each = lookup(lookup(var.liveness_probes, container.key, {}), "type", "") == "exec" ? ["exec"] : []
                content {
                  command = var.liveness_probes[container.key]["exec"]["command"]
                }
              }

              initial_delay_seconds = lookup(lookup(var.liveness_probes, container.key, {}), "initial_delay_seconds", 5)
              timeout_seconds       = lookup(lookup(var.liveness_probes, container.key, {}), "timeout_seconds", 5)
              period_seconds        = lookup(lookup(var.liveness_probes, container.key, {}), "period_seconds", 5)
              failure_threshold     = lookup(lookup(var.liveness_probes, container.key, {}), "failure_threshold", 3)
            }

            readiness_probe {
              dynamic "http_get" {
                for_each = lookup(lookup(var.readiness_probes, container.key, {}), "type", "") == "http_get" ? ["http_get"] : []
                content {
                  path = var.readiness_probes[container.key]["http_get"]["path"]
                  port = var.readiness_probes[container.key]["http_get"]["port"]
                }
              }

              dynamic "tcp_socket" {
                for_each = lookup(lookup(var.readiness_probes, container.key, {}), "type", "") == "tcp_socket" ? ["tcp_socket"] : []
                content {
                  port = var.readiness_probes[container.key]["tcp_socket"]["port"]
                }
              }

              dynamic "exec" {
                for_each = lookup(lookup(var.readiness_probes, container.key, {}), "type", "") == "exec" ? ["exec"] : []
                content {
                  command = var.readiness_probes[container.key]["exec"]["command"]
                }
              }

              initial_delay_seconds = lookup(lookup(var.readiness_probes, container.key, {}), "initial_delay_seconds", 5)
              timeout_seconds       = lookup(lookup(var.readiness_probes, container.key, {}), "timeout_seconds", 5)
              period_seconds        = lookup(lookup(var.readiness_probes, container.key, {}), "period_seconds", 5)
              failure_threshold     = lookup(lookup(var.readiness_probes, container.key, {}), "failure_threshold", 3)
            }

            dynamic "port" {
              for_each = lookup(var.ports, container.key, {})
              content {
                container_port = port.key
                protocol       = port.value["protocol"]
              }
            }

            dynamic "volume_mount" {
              for_each = lookup(var.volume_mounts, container.key, {})
              content {
                name       = volume_mount.key
                read_only  = lookup(volume_mount.value, "read_only", true)
                mount_path = volume_mount.value["mount_path"]
                sub_path   = lookup(volume_mount.value, "sub_path", "")
              }
            }

            dynamic "volume_mount" {
              for_each = lookup(var.volumes_mounts_from_config_map, container.key, {})
              content {
                name       = volume_mount.key
                read_only  = lookup(volume_mount.value, "read_only", true)
                mount_path = volume_mount.value["mount_path"]
                sub_path   = lookup(volume_mount.value, "sub_path", "")
              }
            }

            dynamic "volume_mount" {
              for_each = lookup(var.volumes_mounts_from_secret, container.key, {})
              content {
                name       = volume_mount.key
                read_only  = lookup(volume_mount.value, "read_only", true)
                mount_path = volume_mount.value["mount_path"]
                sub_path   = lookup(volume_mount.value, "sub_path", "")
              }
            }

            dynamic "env" {
              for_each = lookup(var.environment_variables, container.key, {})
              content {
                name  = env.key
                value = env.value
              }
            }

            dynamic "env" {
              for_each = lookup(var.environment_variables_from_secret, container.key, {})
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
