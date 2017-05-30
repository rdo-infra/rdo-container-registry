#!/bin/bash
set -e
export RDO_GITHUB_CLIENT_ID=oauth_client_id
export RDO_GITHUB_CLIENT_SECRET=oauth_client_secret

function cleanup() {
    # This is used so that openshift-ansible is not in CWD when initializing
    # tox which makes it take forever to bootstrap the virtualenv
    rm -rf openshift-ansible
}

# This runs on localhost but uses registry.rdoproject.org resources
for host in registry.rdoproject.org console.registry.rdoproject.org trunk.registry.rdoproject.org
do
    if ! grep -q "127.0.0.1 ${host}" /etc/hosts; then
        echo "127.0.0.1 ${host}" | sudo tee -a /etc/hosts
    fi
done

cleanup
tox -e ansible-playbook -- -i hosts host-preparation.yml
cleanup
tox -e ansible-playbook -- -i hosts openshift-ansible/playbooks/byo/config.yml

sudo oc get pods
sudo oc get routes
sudo oc get svc
