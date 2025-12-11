provider "kind" {}

resource "kind_cluster" "devops_cluster" {
  name           = "devops-cluster"
  wait_for_ready = true

  kind_config {
    kind        = "Cluster"
    api_version = "kind.x-k8s.io/v1alpha4"

    node {
      role = "control-plane"

      kubeadm_config_patches = [
        <<-EOT
          kind: InitConfiguration
          nodeRegistration:
            kubeletExtraArgs:
              node-labels: "ingress-ready=true"
          ---
          kind: ClusterConfiguration
          apiServer:
            extraArgs:
              "service-node-port-range": "80-32767"
        EOT
      ]

      extra_port_mappings {
        container_port = 80
        host_port      = 80
        protocol       = "TCP"
      }

      extra_port_mappings {
        container_port = 443
        host_port      = 443
        protocol       = "TCP"
      }
    }

    node {
      role = "worker"
    }
  }
}

# Local registry configuration
resource "null_resource" "local_registry" {
  depends_on = [kind_cluster.devops_cluster]

  provisioner "local-exec" {
    command = <<-EOT
      docker run -d --restart=always -p 5555:5555 --name kind-registry registry:2 || true
      docker network connect kind kind-registry 2>/dev/null || true
    EOT
  }

  triggers = {
    cluster_id = kind_cluster.devops_cluster.id
  }
}
