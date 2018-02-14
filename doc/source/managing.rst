How to get the service account tokens:
======================================

.. note:: These operation is done directly on the master

Retrieve service account token for image pushes (for CI and things like that)::

    oc describe serviceaccount tripleo.service -n tripleo
    oc describe secret tripleo.service-token-<generated> -n tripleo

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
registry storage. Images should only be deleted by the ``oadm prune images``
command.

The process for pruning images currently looks like this:

- Retrieve a list of ImageStreamTags that are older than **N** days and filter
  that list through a whitelist of excluded tags (i.e, "latest", "tested", etc)
- Delete the matched tags
- Run the oadm prune images command


More reading
~~~~~~~~~~~~

- https://docs.openshift.com/container-platform/latest/admin_guide/manage_authorization_policy.html
- https://docs.openshift.com/container-platform/latest/dev_guide/projects.html
- https://docs.openshift.com/container-platform/latest/admin_guide/service_accounts.html
- https://docs.openshift.com/container-platform/latest/admin_guide/pruning_resources.html#pruning-images
