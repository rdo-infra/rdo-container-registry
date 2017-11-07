Managing the registry
=====================

.. warning:: This should eventually be automated, see
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

More reading
~~~~~~~~~~~~

- https://docs.openshift.com/container-platform/latest/admin_guide/manage_authorization_policy.html
- https://docs.openshift.com/container-platform/latest/dev_guide/projects.html
- https://docs.openshift.com/container-platform/latest/admin_guide/service_accounts.html
