Troubleshooting the registry
============================

.. warning:: Fleshing out this documentation is a work in progress.

::

    # Logs for the origin-master process
    journalctl -u origin-master --follow

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

