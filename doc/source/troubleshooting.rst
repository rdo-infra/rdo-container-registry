Troubleshooting the registry
============================

.. warning:: Fleshing out this documentation is a work in progress.

::

    # Logs for the OpenShift processes
    journalctl -u origin-master-api --follow
    journalctl -u origin-master-controllers --follow
    journalctl -u origin-node --follow

    # Note, commands using -n default is to select from the default namespace

    # List routes, pods and services
    oc get routes -n default
    oc get pods -n default
    oc get svc -n default

    # Dump configuration of things
    oc export routes -n default -o yaml |less
    oc export pods -n default -o yaml |less
    oc export svc -n default -o yaml |less

    # Follow logs from running pods
    oc get pods -n default
    oc logs -f -n default <pod name> (ex: oc logs -f -n default docker-registry-1-xgxqb)

    # Execute a command in a running pod
    oc get pods -n default
    oc exec -n default <pod name> <command> (ex: oc exec -n default docker-registry-1-xgxqb ls)

    # Get a shell on a running pod
    oc get pods -n default
    oc rsh <pod name> -n default (ex: oc rsh docker-registry-1-xgxqb -n default)

    # Look at policies and permissions for a project
    oc get rolebindings -n project

    # If authentication on the master node doesn't seem right
    # You might be logged on as a different user
    oc whoami
    oc login -u system:admin --config=/etc/origin/master/admin.kubeconfig
    oadm config get-contexts
    oadm config use-context default/192-168-1-17:8443/system:admin
