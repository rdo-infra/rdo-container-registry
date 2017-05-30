Using the registry
==================

.. warning:: Fleshing out this documentation is a work in progress.

Pulling containers
------------------

``docker pull trunk.registry.rdoproject.org/<namespace>/<container>(:<tag>)``

Examples::

  docker pull trunk.registry.rdoproject.org/tripleo/centos-binary-base:latest-passed-ci
  docker pull trunk.registry.rdoproject.org/developer/centos

Pushing containers
------------------

Before you can push containers, you need to log in to the registry using
the ``docker login`` command.

In order to use the ``docker login`` command, you need to obtain a token first.
This token is obtained by logging on to the `registry console`_.

In order to log in to the registry console, you need to be a member of a
specific `GitHub team`_ which grants the required access.

After you have successfully logged in to the console, the home page will provide
the login command that you can copy & paste, it looks like this::

    docker login -p abcdef_token -e unused -u unused trunk.registry.rdoproject.org

Afterwards, you may push container images to projects in which you have the necessary
privileges, for example::

    docker pull docker.io/centos
    docker tag docker.io/centos trunk.registry.rdoproject.org/myproject/centos
    docker push trunk.registry.rdoproject.org/myproject/centos

.. _registry console: https://console.registry.rdoproject.org
.. _GitHub team: https://github.com/orgs/rdo-infra/teams/registry-rdoproject-org

Listing containers
------------------

The OpenShift client has the ability to list available container images in a
project over CLI.

To install the OpenShift client::

    # On Fedora
    dnf -y install origin-clients

    # On CentOS
    yum -y install centos-release-openshift-origin
    yum -y install origin-clients

If you have an account
~~~~~~~~~~~~~~~~~~~~~~

If you have an account and are able to log in to the `registry console`_, it
will provide a login command that you can copy & paste, it looks like this::

    oc login --token abcdef_token registry.rdoproject.org:8443

After you have logged in, you may list container images for any project you have
access to::

    oc get imagestreams -n tripleo
    NAME                           DOCKER REPO                                                TAGS     UPDATED
    centos-binary-aodh-api         172.30.132.198:5000/tripleo/centos-binary-aodh-api         latest   2 hours ago
    centos-binary-aodh-base        172.30.132.198:5000/tripleo/centos-binary-aodh-base        latest   2 hours ago
    centos-binary-aodh-evaluator   172.30.132.198:5000/tripleo/centos-binary-aodh-evaluator   latest   2 hours ago

.. note:: Note that the DOCKER REPO field contains an internal URL.
          This will be improved to show the public registry endpoint in a
          future version of OpenShift, in the meantime, you can substitute that
          URL by ``trunk.registry.rdoproject.org``.

If you do not have an account
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

If you do not have an account and you are not able to log in to the
`registry console`_, you will only be able to list container images for
projects that are *public* (*anonymous*).

You will need to create a configuration file in order to tell your OpenShift
client where the OpenShift cluster is located in order to send it's queries.

This configuration file is located at ``~/.kube/config`` and needs to look like
the following::

    apiVersion: v1
    clusters:
    - cluster:
        server: https://registry.rdoproject.org:8443
      name: registry-rdoproject-org:8443
    contexts:
    - context:
        cluster: registry-rdoproject-org:8443
        namespace: default
    kind: Config
    preferences: {}

Once the configuration file is set up, you can list images for public projects,
for example::

    oc get imagestreams -n tripleo
    NAME                           DOCKER REPO                                                TAGS     UPDATED
    centos-binary-aodh-api         172.30.132.198:5000/tripleo/centos-binary-aodh-api         latest   2 hours ago
    centos-binary-aodh-base        172.30.132.198:5000/tripleo/centos-binary-aodh-base        latest   2 hours ago
    centos-binary-aodh-evaluator   172.30.132.198:5000/tripleo/centos-binary-aodh-evaluator   latest   2 hours ago

.. note:: Note that the DOCKER REPO field contains an internal URL.
          This will be improved to show the public registry endpoint in a
          future version of OpenShift, in the meantime, you can substitute that
          URL by ``trunk.registry.rdoproject.org``.
