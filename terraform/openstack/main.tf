# Define required providers
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# Configure the OpenStack Provider and choose the cloud to use
provider "openstack" {
  cloud = var.iac_ad_cloud # Name of the cloud to use, usually set in ~/.config/openstack/clouds.yaml.
  # Alternatively, you can specify the credentials below.

  # user_name   = "admin"
  # tenant_name = "admin"
  # password    = "pwd"
  # auth_url    = "http://myauthurl:5000/v2.0"
  # region      = "RegionOne"
}

module "network" {
  source = "./modules/network"

  subnet_cidr         = var.iac_ad_subnet_cidr
  external_network_id = var.iac_ad_external_network_id
  # server_ports        = var.iac_ad_server_ports
  wireguard_port      = var.iac_ad_wireguard_port
}

# ===============================
# Modules
# ===============================
module "vulnbox" {
  source = "./modules/vulnbox"
  count  = var.iac_ad_vulnbox_count

  team_id = count.index + 1

  vulnbox_flavor_name = var.iac_ad_vulnbox_flavor_name
  vulnbox_image_id    = var.iac_ad_vulnbox_image_id

  floating_ip_pool    = var.iac_ad_floating_ip_pool
  network_id          = module.network.network_id
  vulnbox_secgroup_id = module.network.secgroup_id
  vulnbox_subnet_id   = module.network.subnet_id
}

module "server" {
  source = "./modules/server"

  server_flavor_name = var.iac_ad_server_flavor_name
  server_image_id    = var.iac_ad_server_image_id

  floating_ip_pool   = var.iac_ad_floating_ip_pool
  network_id         = module.network.network_id
  server_secgroup_id = module.network.secgroup_id
  server_subnet_id   = module.network.subnet_id
}

# ===============================
# Outputs
# ===============================
output "private_key_vulnbox" {
  value     = module.vulnbox[*].private_key
  sensitive = true
}
output "private_key_server" {
  value     = module.server.private_key
  sensitive = true
}
output "private_ip_vulnbox" {
  value = module.vulnbox[*].private_ip
}
output "private_ip_server" {
  value = module.server.private_ip
}
output "public_ip_server" {
  value = module.server.public_ip
}
output "public_ip_vulnbox" {
  value = module.vulnbox[*].public_ip
}
