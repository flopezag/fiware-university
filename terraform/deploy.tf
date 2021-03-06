#
# Create a security group
#
resource "openstack_compute_secgroup_v2" "sec_group" {
    region = ""
    name = "swarmcluster_sec_group"
    description = "Security Group Via Terraform for Master Node"
    rule {
        from_port = 22
        to_port = 22
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }

    rule {
        from_port = 2377
        to_port = 2377
        ip_protocol = "tcp"
        cidr = "0.0.0.0/0"
    }
}

#
# Create a keypair
#
resource "openstack_compute_keypair_v2" "swarm_keypair" {
  region = var.openstack_region
  name = "swarm_keypair"
}


#
# Create network interface
#
resource "openstack_networking_network_v2" "network" {
  name = "dockerswarm_network"
  admin_state_up = "true"
  region = var.openstack_region
}

resource "openstack_networking_subnet_v2" "subnetwork" {
  name = "dockerswarm_subnetwork"
  network_id = openstack_networking_network_v2.network.id
  cidr = "10.0.0.0/24"
  ip_version = 4
  dns_nameservers = ["8.8.8.8","8.8.4.4"]
  region = var.openstack_region
}

resource "openstack_networking_router_v2" "router" {
  name = "dockerswarm_router"
  admin_state_up = "true"
  region = var.openstack_region
  external_network_id = data.openstack_networking_network_v2.network.id
}

resource "openstack_networking_router_interface_v2" "router_interface" {
  router_id = openstack_networking_router_v2.router.id
  subnet_id = openstack_networking_subnet_v2.subnetwork.id
  region = var.openstack_region
}


#
# Create an Openstack Floating IP for the Main VM
#
resource "openstack_compute_floatingip_v2" "dockerswarm_floating_ip_master" {
    region = var.openstack_region
    pool = "public-ext-net-01"
}

resource "openstack_compute_floatingip_v2" "dockerswarm_floating_ip_worker1" {
    region = var.openstack_region
    pool = "public-ext-net-01"
}

resource "openstack_compute_floatingip_v2" "dockerswarm_floating_ip_worker2" {
    region = var.openstack_region
    pool = "public-ext-net-01"
}

#
# Create the VM Instance for Security Scan
#
# docker swarm nodes
variable "nodes" {
  default = {
    0 = "swarm-master"
    1 = "swarm-worker1"
    2 = "swarm-worker2"
  }
}

resource "openstack_compute_instance_v2" "swarm_cluster" {
  for_each = var.nodes
  name = each.value
  image_name = var.image
  availability_zone = var.availability_zone
  flavor_name = var.openstack_flavor
  key_pair = openstack_compute_keypair_v2.swarm_keypair.name
  security_groups = [openstack_compute_secgroup_v2.sec_group.name]
  network {
    uuid = openstack_networking_network_v2.network.id
  }
}

#
# Associate public IPs to the Docker Swarm Master
#
resource "openstack_compute_floatingip_associate_v2" "associate_fip_master" {
  floating_ip = openstack_compute_floatingip_v2.dockerswarm_floating_ip_master.address
  instance_id = openstack_compute_instance_v2.swarm_cluster[0].id
}

resource "openstack_compute_floatingip_associate_v2" "associate_fip_worker1" {
  floating_ip = openstack_compute_floatingip_v2.dockerswarm_floating_ip_worker1.address
  instance_id = openstack_compute_instance_v2.swarm_cluster[1].id
}

resource "openstack_compute_floatingip_associate_v2" "associate_fip_worker2" {
  floating_ip = openstack_compute_floatingip_v2.dockerswarm_floating_ip_worker2.address
  instance_id = openstack_compute_instance_v2.swarm_cluster[2].id
}

# Generate the output files (keypair and inventory) for ansible
locals {
  template_keypair_init = templatefile("${path.module}/templates/keypair.tpl", {
    keypair = openstack_compute_keypair_v2.swarm_keypair.private_key
  }
  )

  template_inventory_init = templatefile("${path.module}/templates/ansible_inventory.tpl", {
    connection_string_master = join("\n",
           formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu ansible_connection=ssh",
                        openstack_compute_instance_v2.swarm_cluster[0].name,
                        openstack_compute_floatingip_v2.dockerswarm_floating_ip_master.address))

    connection_string_workers = join("\n",
           formatlist("%s ansible_ssh_host=%s ansible_ssh_user=ubuntu ansible_connection=ssh\n%s ansible_ssh_host=%s ansible_ssh_user=ubuntu ansible_connection=ssh",
                        openstack_compute_instance_v2.swarm_cluster[1].name,
                        openstack_compute_floatingip_v2.dockerswarm_floating_ip_worker1.address,
                        openstack_compute_instance_v2.swarm_cluster[2].name,
                        openstack_compute_floatingip_v2.dockerswarm_floating_ip_worker2.address))

    master_name = var.nodes[0]
    list_nodes = [var.nodes[1], var.nodes[2]]
  }
  )

}

resource "local_file" "keypair_file" {
  content = local.template_keypair_init
  filename = "../ansible/keypair"
  file_permission = "0600"
}

resource "local_file" "ansible_inventory" {
  content = local.template_inventory_init
  filename = "../ansible/inventory.ini"
  file_permission = "0600"
}