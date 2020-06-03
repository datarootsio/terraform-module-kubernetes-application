resource "kubernetes_horizontal_pod_autoscaler" "hpa" {
  for_each = lookup(var.hpa, "enabled", false) == true ? { "hpa" = "true" } : {}

  metadata {
    name      = var.name
    namespace = var.namespace

    labels = {
      app = var.name
    }
  }

  spec {
    max_replicas = lookup(var.hpa, "max_replicas", 6)
    min_replicas = lookup(var.hpa, "min_replicas", 2)

    scale_target_ref {
      api_version = "apps/v2beta2"
      kind        = "Deployment"
      name        = var.name
    }

    dynamic "metric" {
      for_each = lookup(var.hpa, "target_cpu", "") != "" ? { "cpu" = "true" } : {}
      content {
        type = "Resource"
        resource {
          name = "cpu"
          target {
            type                = "Utilization"
            average_utilization = lookup(var.hpa, "target_cpu", 100)
          }
        }
      }
    }

    dynamic "metric" {
      for_each = lookup(var.hpa, "target_memory", "") != "" ? { "memory" = "true" } : {}
      content {
        type = "Resource"
        resource {
          name = "memory"
          target {
            type                = "Utilization"
            average_utilization = lookup(var.hpa, "target_memory", 100)
          }
        }
      }
    }
  }
}
