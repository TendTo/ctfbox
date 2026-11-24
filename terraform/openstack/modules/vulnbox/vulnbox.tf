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
  name = "vulnbox_key_pair_${var.team_id}"
}


# ===============================
# Public IP
# ===============================
resource "openstack_networking_floatingip_v2" "public_ip" {
  pool        = var.floating_ip_pool
  description = "Public IP used to access the vulnbox"
}

# ===============================
# Add public ip to vulnbox
# ===============================
resource "openstack_compute_floatingip_associate_v2" "public_ip_association" {
  floating_ip = openstack_networking_floatingip_v2.public_ip.address
  instance_id = openstack_compute_instance_v2.vulnbox.id
  fixed_ip    = openstack_compute_instance_v2.vulnbox.network.0.fixed_ip_v4
}


# ===============================
# Vulnbox port to the subnet
# ===============================
resource "openstack_networking_port_v2" "vulnbox_port" {
  name           = "vulnbox_port_${var.team_id}"
  admin_state_up = true
  network_id     = var.network_id

  security_group_ids = [
    var.vulnbox_secgroup_id
  ]

  fixed_ip {
    subnet_id = var.vulnbox_subnet_id
  }
}

# ===========================================
# Vulnbox instance
# ===========================================
resource "openstack_compute_instance_v2" "vulnbox" {
  name        = "vulnbox_instance_${var.team_id}"
  image_id    = var.vulnbox_image_id
  flavor_name = var.vulnbox_flavor_name
  key_pair    = openstack_compute_keypair_v2.keypair.name

  metadata = {
    application = "vunlbox_${var.team_id}"
  }

  # user_data = file("${path.module}/vulnbox_user_data.txt")

  network {
    port = openstack_networking_port_v2.vulnbox_port.id
  }
}
