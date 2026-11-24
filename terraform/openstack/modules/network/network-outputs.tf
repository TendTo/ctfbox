output "network_id" {
  value = openstack_networking_network_v2.network.id
}
output "subnet_id" {
  value = openstack_networking_subnet_v2.subnet.id
}
output "secgroup_id" {
  value = openstack_networking_secgroup_v2.secgroup.id
}
