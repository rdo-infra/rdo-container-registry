host-preparation
================

This is an Ansible version of the necessary pre-requirements documented here:
https://docs.openshift.com/container-platform/3.5/install_config/install/host_preparation.html

It will:

- Install the required packages
- Start and enable NetworkManager
- Set up the API, Registry and Console FQDNs to resolve to 127.0.0.1
- Configure 172.30.0.0/16 as a trusted range for insecure registries
- Configure the docker-network MTU (default: 1400)
- Configure docker-storage-setup to format a block device and remount it as '/var/lib/docker' with the overlay2 storage driver
- Run docker-storage-setup if /var/lib/docker is not yet mounted
- Enable and start Docker
