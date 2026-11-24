output "private_key" {
  value     = openstack_compute_keypair_v2.keypair.private_key
  sensitive = true
}
output "private_ip" {
  value = openstack_compute_instance_v2.vulnbox.network.0.fixed_ip_v4
}
output "public_ip" {
  value = openstack_networking_floatingip_v2.public_ip.address
}
