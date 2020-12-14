# Smart City deployment example

Example of deployment a FIWARE Smart City solution using Terraform + Ansible + OpenStack.


## How to start it

* Create virtualenv and activate it:

      virtualenv -p python3.8 $NAME_VIRTUAL_ENV
      source $NAME_VIRTUAL_ENV/bin/activate

* Install the requirements:

      pip install -r requirements.txt


## Deploy the infrastructure in OpenStack

Firstly, it is needed to define the credentials of your OpenStack environment. 
Edit the setup variables to fit your setup. Open `terraform/terraform.tfvars` 
and setup the variables as explained there.

Afterthat, it is needed to initialize and start the Terraform OpenStack Plugin
(only the first time). Execute the following command inside the terraform folder:

```console
terraform init
```

Next step consists in the execution of the **terraform plan** to check whether 
the execution plan for a configuration matches your expectations before 
provisioning or changing infrastructure.

```console
terraform plan
```

Finally, execute the **terraform apply** to execute the provision of the resources
in the Cloud.

```console
terraform apply -auto-approve  
```

The process to create the network, subnetwork and servers (virtual machines) need 
some times.

In case that we want to destroy and delete all provisioned resources we can execute
the command

```console
terraform destroy -auto-approve
```

Keep in mind that the current example only allow the use of port 22 and 2377. If you
need to deploy some service in the swarm and access to them, you need to specify those 
ports in the `deploy.tf` with a new rule

```console
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
```

Last but not least, the execution of the terraform configuration files generate the 
corresponding keypair file and inventory.ini inside the `ansible` folder automatically.

## Configuration of the infrastructure using Ansible

In this step, our plan is configuring the servers in order to install the Docker Engine,
configuration of the TLS communication between them and the configuration of the Docker
Swarm (Masters and Workers).

>NOTE: In order to execute properly the ansible playbook, it is needed to check that you 
have access to the three servers. To do it, just execute the ssh command
> 
> ```console
> ssh -i keypair ubuntu@<ip address>
> ```
> 
>Sometimes, it is needed some time to associate the public IP to the instances. Another 
> typical issue is that you had the public IP associated to a previous server in your 
> `known_hosts` and you receive a response in the execution of the ssh command like it:
> 
> ```console
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> @    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
> @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
> 
> IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
> Someone could be eavesdropping on you right now (man-in-the-middle attack)!
> It is also possible that a host key has just been changed.
> The fingerprint for the ECDSA key sent by the remote host is
> SHA256:E69xngV6za+Uoo8ZrBiO4KpHWjUTwz+xM55lYtxYDK8.
> Please contact your system administrator.
> Add correct host key in /Users/foo/.ssh/known_hosts to get rid of this message.
> Offending ECDSA key in /Users/foo/.ssh/known_hosts:360
> ECDSA host key for 46.17.108.71 has changed and you have requested strict checking.
> Host key verification failed.
> ```
> 
> The solution is access to your known_hosts and delete the corresponding line to force
> getting a new SHA of the server.


To start the execution of the playbook, just execute the command:

```console
ansible-playbook -i inventory.ini \
--private-key=keypair provision.yml
```

And you will have available the corresponding Docker Swarm up and running to be used.

## License

[Apache2.0](LICENSE) © 2020 FIWARE Foundation e.V.