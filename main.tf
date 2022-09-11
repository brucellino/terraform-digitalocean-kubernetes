# Main definition
data "digitalocean_account" "current" {}

data "digitalocean_droplets" "all" {}
data "digitalocean_kubernetes_versions" "selected" {
  version_prefix = "1.22."
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
  version       = data.digitalocean_kubernetes_versions.selected.latest_version
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

resource "digitalocean_kubernetes_node_pool" "other" {
  count      = var.node_pools
  cluster_id = digitalocean_kubernetes_cluster.c.id
  name       = "apps-${count.index}"
  size       = element(data.digitalocean_sizes.main.sizes, 1).slug
  auto_scale = true
  min_nodes  = 1
  # max_nodes must be half of the droplet limit of surge upgrade is enabled
  max_nodes = floor((data.digitalocean_account.current.droplet_limit - length(data.digitalocean_droplets.all.droplets)) / var.node_pools)
  tags      = ["tfmod-k8s-test", "node-pool-${count.index}"]
  labels = {

  }
}

# firewalls for restricting public access
resource "digitalocean_project_resources" "k8s" {
  project = data.digitalocean_project.k8s.id
  resources = [
    digitalocean_kubernetes_cluster.c.urn
  ]
}
