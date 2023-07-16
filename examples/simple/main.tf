terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.22"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.8"
    }
  }
  required_version = ">=1.5.0"
  backend "consul" {
    path = "tfmod_digitalocean_k8s"
  }
}

# This doesn't seem to work?
data "vault_kv_secret_subkeys_v2" "do_token" {
  mount = "digitalocean"
  name  = "tokens"
}

data "vault_generic_secret" "do_token" {
  path = "digitalocean/tokens"
}

provider "digitalocean" {
  # token = data.vault_kv_secret_subkeys_v2.do_token.data["terraform"]
  token = data.vault_generic_secret.do_token.data["terraform"]
}


module "vpc" {
  source  = "brucellino/vpc/digitalocean"
  version = "1.0.3"
  project = {
    description = "Kubernetes testing",
    environment = "Development",
    name        = "K8s_test",
    purpose     = "personal"
  }
  vpc_name   = "k8s"
  vpc_region = "ams3"
}



module "k8s" {
  depends_on   = [module.vpc]
  source       = "../../"
  k8s_version  = "1.24.13-do.0"
  vpc_name     = "k8s"
  project_name = "K8s_test"
  node_pools = {
    compute = {
      size       = "c-2"
      node_count = 2
      tags = [
        "compute"
      ]
      labels = {
        compute   = true
        workloads = true
      }
      taint = {}
    }
  }
}

output "droplets" {
  value = length(module.k8s.droplets)
}
