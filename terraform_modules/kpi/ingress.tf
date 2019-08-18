#####################################################################
# ingress
#####################################################################

resource "kubernetes_ingress" "kpi_ingress" {
  count = var.gcloud_ingress ? 1 : 0
  metadata {
    name      = "kpi-ingress"
    namespace = var.namespace

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    rule {
      host = "stats.${var.domain}"

      http {
        path {
          path = "/"

          backend {
            service_name = kubernetes_service.grafana_service.metadata[0].name
            service_port = kubernetes_service.grafana_service.spec[0].port[0].port
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "kpi_ingress_local" {
  count = var.gcloud_ingress ? 0 : 1
  metadata {
    name      = "kpi-ingress"
    namespace = var.namespace

    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
    }
  }

  spec {
    tls {
      secret_name = "minikube-ingress-secret"
    }

    rule {
      host = "stats.${var.domain}"

      http {
        path {
          path = "/"

          backend {
            service_name = kubernetes_service.grafana_service.metadata[0].name
            service_port = kubernetes_service.grafana_service.spec[0].port[0].port
          }
        }
      }
    }
  }
}
