#
# show the Public and Private IP addresses of the virtual machines
#
output "SwarmCluster_Master"	{
	value = "${openstack_compute_floatingip_v2.dockerswarm_floating_ip_master.address} initialized with success"
}

output "SwarmCluster_Worker1"	{
	value = "${openstack_compute_floatingip_v2.dockerswarm_floating_ip_worker1.address} initialized with success"
}

output "SwarmCluster_Worker2"	{
	value = "${openstack_compute_floatingip_v2.dockerswarm_floating_ip_worker2.address} initialized with success"
}

output "Keypair" {
	value = openstack_compute_keypair_v2.swarm_keypair.private_key
}
