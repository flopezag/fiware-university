# Contains the web servers at backend network

[cluster]
${connection_strings}
%{ for node_name in list_nodes ~}
${node_name}
%{ endfor ~}

[all:vars]
environment=prod
ansible_python_interpreter=/usr/bin/python3
