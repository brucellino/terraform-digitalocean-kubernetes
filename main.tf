# Main definition
data "digitalocean_account" "current" {}

data "digitalocean_droplets" "all" {}
data "digitalocean_kubernetes_versions" "selected" {
  lifecycle {
    postcondition {
      condition     = self.valid_versions != []
      error_message = "No valid version found"
    }
  }
}

data "digitalocean_sizes" "main" {
  filter {
    key    = "regions"
    values = ["ams3"]
  }

  filter {
    key    = "available"
    values = [true]
  }
  filter {
    key    = "vcpus"
    values = [2]
  }
  sort {
    key       = "price_hourly"
    direction = "asc"
  }
}

data "digitalocean_vpc" "selected" {
  name = var.vpc_name
}

data "digitalocean_project" "k8s" {
  name = var.project_name
}
resource "digitalocean_kubernetes_cluster" "c" {
  name          = "example"
  region        = "ams3"
  version       = data.digitalocean_kubernetes_versions.selected.valid_versions[0]
  surge_upgrade = true
  auto_upgrade  = var.auto_upgrade_enabled
  node_pool {
    name       = "system"
    size       = element(data.digitalocean_sizes.main.sizes, 0).slug
    node_count = 3
    auto_scale = false
    labels = {
      priority = "high"
      service  = "control"
    }
  }
  vpc_uuid = data.digitalocean_vpc.selected.id
  tags     = ["tfmod-k8s-test"]
}

resource "digitalocean_kubernetes_node_pool" "declared" {
  for_each   = var.node_pools
  cluster_id = digitalocean_kubernetes_cluster.c.id
  name       = each.key
  size       = each.value.size
  node_count = each.value.node_count
  tags       = each.value.tags
  labels     = each.value.labels

}

# firewalls for restricting public access


resource "digitalocean_project_resources" "k8s" {
  depends_on = [digitalocean_kubernetes_node_pool.declared]
  project    = data.digitalocean_project.k8s.id
  resources = [
    digitalocean_kubernetes_cluster.c.urn
  ]
}
