# ===============================
# Provider
# ===============================
terraform {
  required_version = ">= 0.14.0"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
  }
}

# ===============================
# Key pair
# ===============================
resource "openstack_compute_keypair_v2" "keypair" {
  name = "server_key_pair"
}

# ===============================
# Public IP
# ===============================
resource "openstack_networking_floatingip_v2" "public_ip" {
  pool        = var.floating_ip_pool
  description = "Public IP used to access the server"
}

# ===============================
# Add public ip to server
# ===============================
resource "openstack_compute_floatingip_associate_v2" "public_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.public_ip.address
  instance_id = openstack_compute_instance_v2.server.id
  fixed_ip    = openstack_compute_instance_v2.server.network.0.fixed_ip_v4
}


# ===============================
# Server port to the subnet
# ===============================
resource "openstack_networking_port_v2" "server_port" {
  name           = "server_port"
  admin_state_up = true
  network_id     = var.network_id

  security_group_ids = [
    var.server_secgroup_id
  ]

  fixed_ip {
    subnet_id = var.server_subnet_id
  }
}

# ===========================================
# Server instance
# ===========================================
resource "openstack_compute_instance_v2" "server" {
  name        = "server_instance"
  image_id    = var.server_image_id
  flavor_name = var.server_flavor_name
  key_pair    = openstack_compute_keypair_v2.keypair.name

  metadata = {
    application = "server"
  }

  network {
    port = openstack_networking_port_v2.server_port.id
  }
}
