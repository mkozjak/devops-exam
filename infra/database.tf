resource "kubernetes_secret" "mysql" {
  metadata {
    name      = "mysql"
    namespace = "default"
  }

  data = {
    MYSQL_ROOT_PASSWORD = base64encode("justan3xamplepassw0rd")
  }
}

# Expose MySQL
resource "kubernetes_service" "mysql" {
  metadata {
    name      = "mysql"
    namespace = "default"
  }

  spec {
    selector = {
      app = "mysql"
    }

    port {
      port        = 3306
      target_port = 3306
    }
  }
}

# Run initial MySQL config on deploy
resource "kubernetes_config_map" "mysql_init_script" {
  metadata {
    name      = "mysql-init-script"
    namespace = "default"
  }

  data = {
    "init.sql" = file("./sql/init.sql")
  }
}

# Run initial MySQL config on deploy
resource "kubernetes_config_map" "mysql_fixtures_script" {
  metadata {
    name      = "mysql-fixtures-script"
    namespace = "default"
  }

  data = {
    "fixtures.sql" = file("./sql/fixtures.sql")
  }
}

# Deploy MySQL to Kubernetes
resource "kubernetes_deployment" "mysql" {
  metadata {
    name      = "mysql"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "mysql"
      }
    }

    template {
      metadata {
        labels = {
          app = "mysql"
        }
      }

      spec {
        container {
          name  = "mysql"
          image = "mysql:8.0"

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = base64decode(kubernetes_secret.mysql.data["MYSQL_ROOT_PASSWORD"])
          }

          port {
            container_port = 3306
          }
        }
      }
    }
  }
}

# Setup the database
resource "kubernetes_job" "mysql_init" {
  depends_on = [ kubernetes_config_map.mysql_init_script ]

  metadata {
    name = "mysql-init"
  }

  spec {
    template {
      metadata {
        labels = {
          app = "mysql-init"
        }
      }

      spec {
        container {
          name            = "mysql-init"
          image           = "ubuntu:latest"
          command         = ["bin/sh", "-c"]
          args            = ["apt update && apt install --yes mysql-client && cat /scripts/init.sql | mysql -h mysql -u root --password=$MYSQL_ROOT_PASSWORD"]

          volume_mount {
            name       = "mysql-init-scripts"
            mount_path = "/scripts"
          }

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = base64decode(kubernetes_secret.mysql.data["MYSQL_ROOT_PASSWORD"])
          }
        }

        restart_policy = "Never"

        volume {
          name     = "mysql-init-scripts"

          config_map {
            name = kubernetes_config_map.mysql_init_script.metadata.0.name
          }
        }
      }
    }
  }
}

# Insert initial values into our database
resource "kubernetes_job" "mysql_fixtures" {
  depends_on = [ kubernetes_config_map.mysql_fixtures_script, kubernetes_job.mysql_init ]

  metadata {
    name = "mysql-fixtures"
  }

  spec {
    template {
      metadata {
        labels = {
          app = "mysql-fixtures"
        }
      }

      spec {
        container {
          name            = "mysql-fixtures"
          image           = "ubuntu:latest"
          command         = ["bin/sh", "-c"]
          args            = ["apt update && apt install --yes mysql-client && cat /scripts/fixtures.sql | mysql -h mysql -u root --password=$MYSQL_ROOT_PASSWORD"]

          volume_mount {
            name       = "mysql-fixtures-scripts"
            mount_path = "/scripts"
          }

          env {
            name  = "MYSQL_ROOT_PASSWORD"
            value = base64decode(kubernetes_secret.mysql.data["MYSQL_ROOT_PASSWORD"])
          }
        }

        restart_policy = "Never"

        volume {
          name     = "mysql-fixtures-scripts"

          config_map {
            name = kubernetes_config_map.mysql_fixtures_script.metadata.0.name
          }
        }
      }
    }
  }
}