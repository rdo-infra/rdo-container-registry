Installing the registry
=======================

.. warning:: Fleshing out this documentation is a work in progress.

Installing SSL certificates
---------------------------

Certificates are provided by LetsEncrypt and are expected to have been generated
prior to the installation. The certificate and key file paths are expected to
have a specific format so that OpenShift doesn't overwrite existing files when
copying them into it's directories::

    yum -y install git

    # Retrieve letsencrypt and run it
    git clone https://github.com/letsencrypt/letsencrypt
    mkdir -p /tmp/letsencrypt

    for domain in registry.rdoproject.org trunk.registry.rdoproject.org console.registry.rdoproject.org
    do
    letsencrypt/letsencrypt-auto --renew-by-default \
      -a standalone \
      --webroot-path /tmp/letsencrypt/ \
      --server https://acme-v01.api.letsencrypt.org/directory \
      --email dmsimard@redhat.com \
      --text \
      --non-interactive \
      --agree-tos \
      -d $domain auth
      sleep 1

      # openshift-ansible gathers all keys and certs to /etc/origin/master/named_certificates
      # Give them unique names so they don't overwrite each other.
      pushd /etc/letsencrypt/live/${domain}
      ln -s privkey.pem ${domain}-privkey.pem
      ln -s cert.pem ${domain}-cert.pem
      ln -s chain.pem ${domain}-chain.pem
      ln -s fullchain.pem ${domain}-fullchain.pem
      popd
    done

Installing OpenShift Standalone Registry
----------------------------------------

To install OpenShift Standalone Registry on ``localhost`` as root:

Set up local key-based authentication::

    # We'll be connecting on localhost over ssh, setup keypair authentication
    ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''
    cat ~/.ssh/id_rsa.pub >>~/.ssh/authorized_keys
    ssh-keyscan -H registry.rdoproject.org >>~/.ssh/known_hosts

Install dependencies::

    yum install -y python-setuptools python-devel libffi-devel openssl-devel redhat-rpm-config git gcc
    easy_install pip
    pip install tox

Export oauth application credentials for github authentication::

    export RDO_GITHUB_CLIENT_ID=oauth_client_id
    export RDO_GITHUB_CLIENT_SECRET=oauth_client_secret

.. note:: /var/lib/docker will be set up on a separate block device with
          docker-storage-setup. If you do not provide the
          ``host_preparation_docker_disk`` variable for the host-preparation
          playbook, a loopback device will be generated with test purposes and
          the playbook will warn you about it.

.. note:: The server stores an OpenShift persistent volume for the Docker
          registry on the local filesystem in ``/openshift_volumes``.
          If you expect a high volume of data, you should re-mount this
          directory on a large partition or volume prior to installation.

.. note:: ansible_ssh_user **MUST** be provided for the openshift-ansible
          playbook, it is required by tasks such as
          ``openshift_master_certificates : Lookup default group for ansible_ssh_user``.

Retrieve and run rdo-container-registry and openshift-ansible playbooks::

    git clone https://github.com/rdo-infra/rdo-container-registry
    cd rdo-container-registry
    tox -e ansible-playbook -- -i hosts -e "host_preparation_docker_disk=/dev/vdb" host-preparation.yml
    # Note: https://github.com/openshift/openshift-ansible/issues/5812
    #       Glean configures "NM_CONTROLLED=no" in the ifcfg-eth0 file
    tox -e ansible-playbook -- -i hosts openshift-ansible/playbooks/byo/openshift-node/network_manager.yml -e "ansible_ssh_user=${USER}"
    tox -e ansible-playbook -- -i hosts openshift-ansible/playbooks/byo/config.yml -e "ansible_ssh_user=${USER}"
