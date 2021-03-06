# Contains the cluster servers for the docker swarm

[master]
${connection_string_master}
${master_name}

[workers]
${connection_string_workers}
%{ for workers_name in list_nodes ~}
${workers_name}
%{ endfor ~}

[all]
${master_name}
%{ for workers_name in list_nodes ~}
${workers_name}
%{ endfor ~}

[all:vars]
environment=prod
ansible_python_interpreter=/usr/bin/python3
