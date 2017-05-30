Installing the registry
=======================

.. warning:: Fleshing out this documentation is a work in progress.

::

    pip install git+https://github.com/rdo-infra/rdo-container-registry
    export RDO_GITHUB_CLIENT_ID=oauth_client_id
    export RDO_GITHUB_CLIENT_SECRET=oauth_client_secret
    tox -e ansible-playbook -- -i hosts -e "host_preparation_docker_disk=/dev/vdb" host-preparation.yml
    tox -e ansible-playbook -- -i hosts openshift-ansible/playbooks/byo/config.yml
