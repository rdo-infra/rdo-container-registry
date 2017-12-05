#!/bin/bash
#   Copyright Red Hat, Inc. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.
#

# Note: if generating certificates after OpenShift has been set up
# oc scale --replicas=0 dc router
# <Generate certs>
# oc scale --replicas=1 dc router

yum -y install git

# Retrieve letsencrypt and run it
git clone https://github.com/letsencrypt/letsencrypt
mkdir -p /tmp/letsencrypt

for domain in registry.rdoproject.org trunk.registry.rdoproject.org console.registry.rdoproject.org registry.distributed-ci.io
do

if [[ domain =~ "distributed-ci.io" ]]; then
    email="distributed-ci@redhat.com"
else
    email="dmsimard@redhat.com"
fi
letsencrypt/letsencrypt-auto --renew-by-default \
  -a standalone \
  --webroot-path /tmp/letsencrypt/ \
  --server https://acme-v01.api.letsencrypt.org/directory \
  --email ${email} \
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
