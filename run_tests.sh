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
echo "127.0.0.1 registry.rdoproject.org" >> /etc/hosts
echo "127.0.0.1 console.registry.rdoproject.org" >> /etc/hosts
echo "127.0.0.1 trunk.registry.rdoproject.org" >> /etc/hosts

cleanup
tox -e ansible-playbook -- -i hosts host-preparation.yml
cleanup
tox -e ansible-playbook -- -i hosts openshift-ansible/playbooks/byo/config.yml

oc get pods
oc get routes
oc get svc
