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
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = var.name
    }
    target_cpu_utilization_percentage = lookup(var.hpa, "target_cpu", 80)
  }
}
