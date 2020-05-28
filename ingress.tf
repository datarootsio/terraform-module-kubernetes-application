resource "kubernetes_ingress" "ingress" {

  for_each = {
    for key, value in local.ports_map :
    key => value
    if lookup(value, "ingress", "") != ""
  }

  metadata {
    name      = "${var.name}-${each.key}"
    namespace = var.namespace
    annotations = merge(
      lookup(local.ingress_annotations, lookup(each.value, "default_ingress_annotations", "none")),
      lookup(each.value, "cert_manager_issuer", "") == "" ? {} : { "cert-manager.io/issuer" = each.value["cert_manager_issuer"] },
      lookup(each.value, "ingress_annotations", {})
    )
  }

  spec {
    dynamic "tls" {
      for_each = lookup(each.value, "cert_manager_issuer", "") == "" ? [] : [lookup(each.value, "cert_manager_issuer", "")]
      content {
        hosts       = [each.value["ingress"]]
        secret_name = "${var.name}-${each.key}"
      }
    }

    rule {
      host = each.value["ingress"]

      http {
        path {
          backend {
            service_name = var.name
            service_port = each.value["port"]
          }
        }
      }
    }
  }
}
