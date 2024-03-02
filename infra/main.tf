provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "docker-desktop"
}

resource "kubernetes_deployment" "swissknife" {
  metadata {
    name = "swissknife-deployment"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "swissknife"
      }
    }

    template {
      metadata {
        labels = {
          app = "swissknife"
        }
      }

      spec {
        container {
          name  = "swissknife"
          image = "ubuntu:latest"
          command = [ "/bin/bash", "-c", "--" ]
          args = [ "while true; do sleep 30; done;" ]
        }
      }
    }
  }
}