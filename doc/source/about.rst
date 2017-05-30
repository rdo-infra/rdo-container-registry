About the registry
==================

RDO uses an `OpenShift standalone registry`_ which is more or less the upstream
for the `Atomic Registry`_ project.

We chose to use the OpenShift standalone registry because it provides features
that ``docker-registry`` and ``docker-distribution`` do not have out of the box.

Some reasons and features include but are not limited to:

- Being able to list images in the registry: ``oc get imagestreams``
- Provide a web interface to browse and manage images in the registry
- Built-in authentication and access control (ACL) with GitHub oauth support
- Dogfood the OpenShift standalone registry use case and establish a feedback loop with OpenShift developers

.. _OpenShift Standalone registry: https://docs.openshift.com/container-platform/latest/install_config/install/stand_alone_registry.html
.. _Atomic Registry: http://www.projectatomic.io/registry/
