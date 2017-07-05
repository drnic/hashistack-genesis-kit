job "hashi-ui" {
  region      = "local"
  datacenters = ["warden"]
  type        = "service"

  update {
    stagger      = "5s"
    max_parallel = 1
  }

  group "server" {
    count = 3
    task "hashi-ui" {
      driver = "docker"

      config {
        image        = "jippi/hashi-ui"
        network_mode = "host"
      }

      env {
        LISTEN_ADDR = "0.0.0.0:NOMAD_PORT_http"

        NOMAD_ENABLE = 1
        NOMAD_ADDR   = "https://nomad.service.consul:4646"
        NOMAD_SKIP_VERIFY = 1

        CONSUL_ENABLE = 1
        CONSUL_ADDR   = "localhost:8501"
      }

      service {
        name = "hashi-ui"
        tags = [
          "traefik.tags=enabled",
          "traefik.frontend.rule=HostRegexp:hashi-ui.{domain:.*}",
          "traefik.frontend.entryPoints=admin"
        ]

        port = "http"
        check {
          type     = "http"
          path     = "/nomad"
          interval = "5s"
          timeout  = "2s"
        }
      }

      resources {
        cpu    = 250
        memory = 128

        network {
          mbits = 1
          port "http" {}
       }
      }
    }
  }
}
