Managing the registry
=====================

.. warning:: A lot of this should eventually be automated, see
             https://github.com/rdo-infra/rdo-container-registry/issues/1

.. note:: These operations are done directly on the master

::

    # Grant superuser privileges to a user (doesn't require the user to login before applying)
    oadm policy add-cluster-role-to-user cluster-admin dmsimard

    # Create projects
    oc new-project master \
      --description="TripleO container images for trunk and continuous integration for OpenStack 'master'" \
      --display-name="TripleO container images for 'master'"

    oc new-project pike \
      --description="TripleO container images for trunk and continuous integration for OpenStack 'pike'" \
      --display-name="TripleO container images for 'pike'"

    # Allow authenticated users to browse the projects
    # Note:
    #  - https://github.com/cockpit-project/cockpit/issues/6711
    #  - https://github.com/openshift/origin/issues/14381
    oc policy add-role-to-group registry-viewer system:authenticated -n master
    oc policy add-role-to-group registry-viewer system:authenticated -n pike

    # Allow unauthenticated users to pull images from the projects
    # (Anonymous, public access to registry, not the actual console)
    oc policy add-role-to-group registry-viewer system:unauthenticated -n master
    oc policy add-role-to-group registry-viewer system:unauthenticated -n pike

    # Create service account, make it admin of the projects
    oc create serviceaccount tripleo.service -n default

    # Add permissions for the service account to push and pull images
    oc policy add-role-to-user system:image-builder system:serviceaccount:default:tripleo.service -n master
    oc policy add-role-to-user system:image-builder system:serviceaccount:default:tripleo.service -n pike

    # Retrieve service account token for image pushes, for example when doing CI
    oc describe serviceaccount tripleo.service -n default
    oc describe secret tripleo.service-token-<generated> -n default

    # Login as rdo.pruner service account
    source /root/login.pruner.sh
    # Login as system.admin account
    source /root/login.admin.sh

Pruning images
~~~~~~~~~~~~~~

To understand what image pruning does, you first need to understand that there
are different components:

- **Images** are references to image **layers** (or blobs). **Never** delete those directly!
  - Example: *sha256:0001ce35a7c10c526a138c2fe9c8e6522e4aefd7d89c1d639fe3fe5b6f1e3631*
- **ImageStreams** are a set of images, or layers, which is typically referred to as a Docker container image
  - Example: *alpine*
- **ImageStreamTags** are tags given to ImageStream to easily identify them
  - Example: *latest*

When pruning ``images``, what you are doing is deleting ``images`` (layers)
that are no longer referenced by any ``ImageStreams`` or ``ImageStreamTags``.

Pruning by itself doesn't accomplish anything if there isn't any orphaned
images so, in order to be effective, either the operator or the tenant needs
to regularly delete ``ImageStreams`` or ``ImageStreamTags`` that are no longer
required.

Do not ever delete ``images`` directly. This will delete the reference to the
layer in OpenShift's etcd instance without deleting the actual blob in the
registry storage. Images should only be deleted by the ``oc prune images``
command.

The process for pruning images currently looks like this:

- Retrieve a list of ImageStreamTags that are older than **N** days and filter
  that list through a whitelist of excluded tags (i.e, "latest", "tested", etc)
- Delete the matched tags
- Run the oc prune images command

More reading
~~~~~~~~~~~~

- https://docs.openshift.com/container-platform/latest/admin_guide/manage_authorization_policy.html
- https://docs.openshift.com/container-platform/latest/dev_guide/projects.html
- https://docs.openshift.com/container-platform/latest/admin_guide/service_accounts.html
- https://docs.openshift.com/container-platform/latest/admin_guide/pruning_resources.html#pruning-images