Managing the registry
=====================

.. warning:: Fleshing out this documentation is a work in progress.

.. note:: These operations are done directly on the master

::

    # Retrieve service account token for image pushes (for CI and things like that)
    oc describe serviceaccount tripleo.service -n tripleo
    oc describe secret tripleo.service-token-<generated> -n tripleo
