# variables.tf
# Use this file to declare the variables that the module will use.

# A dummy variable is provided to force a test validation
variable "vpc_name" {
  type        = string
  description = "Name of the VPC we are using to deploy into"
}

variable "project_name" {
  type        = string
  default     = ""
  description = "Project name to associate the cluster with."
}

variable "node_pools" {
  type        = number
  description = "Number of extra node pools to add to the cluster"
  default     = 0
}

variable "auto_upgrade_enabled" {
  type        = bool
  default     = true
  description = "Whether or not to turn on auto upgrade"
}

output "droplets" {
  value = data.digitalocean_droplets.all.droplets
}
