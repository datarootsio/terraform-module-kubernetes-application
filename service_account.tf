resource "kubernetes_service_account" "serviceaccount" {
  metadata {
    name      = var.name
    namespace = var.namespace

    labels = {
      app = var.name
    }
  }

  automount_service_account_token = true
}
