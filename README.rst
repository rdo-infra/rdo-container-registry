rdo-container-registry
======================
RDO community standalone OpenShift Registry configuration, deployment and
documentation_.

.. _documentation: https://rdo-container-registry.readthedocs.io/en/latest/

Note: this is a work in progress
================================

The following patches were submitted and merged upstream in order to make this work:

- Don't set-up origin repositories if they've already been configured:
  https://github.com/openshift/openshift-ansible/commit/0414e424c90000a9aa393a1d47404b726a2443d3

- Add teams attribute to github identity provider:
  https://github.com/openshift/openshift-ansible/commit/1a43e7da5f69d5015ed5dafca50f80f2c8ec528d

- Allow a hostname to resolve to 127.0.0.1 during validation:
  https://github.com/openshift/openshift-ansible/commit/9260dcd084f19ec5a641c2673525163d5ab76816

- Support enabling the centos-openshift-origin-testing repository:
  https://github.com/openshift/openshift-ansible/commit/ac8f77887acae94a789f4b8fdc1f3f18a4446024

- Refactor openshift_hosted's docker-registry route setup:
  https://github.com/openshift/openshift-ansible/commit/00afac6ef3235ab66e0a0c02cc863cb577e127f2

Work is still in progress to merge the some patches. While these are pending,
they are rebased and cherry-picked together a forked branch at
https://github.com/dmsimard/openshift-ansible/tree/rdo

- Refactor registry-console setup and add support for SSL:
  https://github.com/openshift/openshift-ansible/pull/4256

- Add support for hostpath persistent volume definitions
  https://github.com/openshift/openshift-ansible/pull/6022
