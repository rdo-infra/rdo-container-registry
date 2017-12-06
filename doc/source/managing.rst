How to get the service account tokens:
======================================

.. note:: These operation is done directly on the master

Retrieve service account token for image pushes (for CI and things like that)::

    oc describe serviceaccount tripleo.service -n tripleo
    oc describe secret tripleo.service-token-<generated> -n tripleo

More reading
~~~~~~~~~~~~

- https://docs.openshift.com/container-platform/latest/admin_guide/manage_authorization_policy.html
- https://docs.openshift.com/container-platform/latest/dev_guide/projects.html
- https://docs.openshift.com/container-platform/latest/admin_guide/service_accounts.html
