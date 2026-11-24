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
# Network
# ===============================
resource "openstack_networking_network_v2" "network" {
  name           = "iac_ad_network"
  admin_state_up = true
}

# ===============================
# External router
# ===============================
resource "openstack_networking_router_v2" "external_router" {
  name                = "external_router"
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "external_router_interface_subnet" {
  router_id = openstack_networking_router_v2.external_router.id
  subnet_id = openstack_networking_subnet_v2.subnet.id
}

# ===========================================
# Subnets
# ===========================================
resource "openstack_networking_subnet_v2" "subnet" {
  name            = "iac_ad_subnet"
  network_id      = openstack_networking_network_v2.network.id
  cidr            = var.subnet_cidr
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.8.4"]
}

# ===============================
# Security groups
# ===============================
resource "openstack_networking_secgroup_v2" "secgroup" {
  name                 = "iac_ad_secgroup"
  description          = "Security group for the vulnboxes"
  delete_default_rules = true
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_egress_v4" {
  direction         = "egress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_egress_v6" {
  direction         = "egress"
  ethertype         = "IPv6"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}

resource "openstack_networking_secgroup_rule_v2" "secgroup_rule_ingress_v4" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
}
