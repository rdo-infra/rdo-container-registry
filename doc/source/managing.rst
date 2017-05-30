Managing the registry
=====================

.. warning:: Fleshing out this documentation is a work in progress.

.. note:: These operations are done directly on the master

::

    # Grant superuser privileges to a user once he has logged in at least once
    # https://docs.openshift.com/container-platform/3.5/admin_guide/manage_authorization_policy.html
    oc policy add-role-to-user cluster-admin dmsimard

    # Create project
    oc new-project tripleo \
      --description="TripleO container images for trunk and continuous integration" \
      --display-name="TripleO container images"

    # Create service account, make it admin of the project
    oc create serviceaccount tripleo.service -n tripleo
    oc policy add-role-to-user admin system:serviceaccount:tripleo:tripleo.service -n tripleo

    # Retrieve service account token for image pushes (for CI and things like that)
    oc describe serviceaccount tripleo.service -n tripleo
    oc describe secret tripleo.service-token-<generated> -n tripleo

    # Allow authenticated users to browse the TripleO project
    # Note: https://github.com/cockpit-project/cockpit/issues/6711
    oc policy add-role-to-group registry-viewer system:authenticated -n tripleo
