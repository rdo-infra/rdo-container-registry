#!/usr/bin/env python
#   Copyright Red Hat, Inc. All Rights Reserved.
#
#   Licensed under the Apache License, Version 2.0 (the "License"); you may
#   not use this file except in compliance with the License. You may obtain
#   a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#   WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#   License for the specific language governing permissions and limitations
#   under the License.
#

import argparse
from datetime import datetime
import json
import logging
import logging.config
import os
import shlex
import subprocess
import sys
import time
import yaml


def setup_logging(level):
    log_config = """
    ---
    version: 1
    formatters:
        console:
            format: '%(asctime)s %(levelname)s %(name)s: %(message)s'
    handlers:
        console:
            class: logging.StreamHandler
            formatter: console
            level: {level}
            stream: ext://sys.stdout
    loggers:
        {name}:
            handlers:
                - console
            level: {level}
            propagate: 0
    root:
      handlers:
        - console
      level: {level}
    """.format(name=os.path.basename(__file__), level=level).lstrip()
    logging.config.dictConfig(yaml.safe_load(log_config))


def get_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--debug', help='Enable debug logging',
                        action='store_true')
    parser.add_argument('--confirm', help='Confirm the deletion of the tags'
                                          ' (Dry-run by default)',
                        action='store_true')
    parser.add_argument('--days', help='Delete tags older than N days',
                        default=7)
    parser.add_argument('--whitelist', help='Comma-separated list of tags to'
                                            ' whitelist',
                        default=None)
    parser.add_argument('namespace', help='Namespace to prune old tags in')
    args = parser.parse_args()
    return args


def run_command(command, log, fatal=False, confirm=False):
    if not confirm:
        log.info("Not running (dry-run): %s" % command)
        return True, ""

    try:
        log.debug("Running: %s" % command)
        output = subprocess.check_output(shlex.split(command),
                                         stderr=subprocess.PIPE)
        return True, output
    except subprocess.CalledProcessError as e:
        if fatal:
            log.critical("Command failed: %s" % e.output)
            raise e
        else:
            return False, e.output


def main():
    args = get_args()
    level = "DEBUG" if args.debug else "INFO"
    setup_logging(level)
    log = logging.getLogger(os.path.basename(__file__))
    log.debug("Arguments: %s" % json.dumps(args.__dict__))
    if not args.confirm:
        log.warn("{0} RUNNING IN DRY MODE {0}".format("*" * 10))
    else:
        log.warn("{0} CONFIRMED DELETION OF TAGS {0}".format("*" * 10))
        time.sleep(5)

    # Seconds in a day * args.days
    MAX_AGE = 86400 * args.days
    NOW = datetime.utcnow()

    # Load whitelisted tags if there's any
    whitelist = []
    if args.whitelist is not None:
        whitelist = args.whitelist.split(',')
        log.info('Whitelisted tags: %s' % ', '.join(whitelist))
    else:
        log.warn("No whitelist has been provided, all tags will be pruned.")

    log.info("Deleting tags from %s older than %s days" % (args.namespace,
                                                           args.days))

    try:
        cmd = "oc get -n %s istag -o json" % args.namespace
        # This should always run regardless of dry-run
        success, istags = run_command(cmd, log, confirm=True, fatal=True)
        istags = json.loads(istags)
    except (ValueError, TypeError) as e:
        # Re-raise with a slightly friendlier message
        log.critical("Unable to load tags from JSON: %s" % str(e))
        raise e

    log.info("%s tags found." % len(istags['items']))
    whitelisted = []
    old_tags = []
    for istag in istags['items']:
        # Get the name, tag and creation timestamp of the image stream tag
        name, tag = istag['metadata']['name'].split(':')
        timestamp = istag['metadata']['creationTimestamp']
        timestamp = datetime.strptime(timestamp, '%Y-%m-%dT%H:%M:%SZ')

        # If the image is older than MAX_AGE, add it to the list to delete
        delta = NOW - timestamp
        if tag in whitelist:
            log.debug("%s:%s is whitelisted" % (name, tag))
            whitelisted.append("%s:%s" % (name, tag))
        else:
            if delta.total_seconds() > MAX_AGE:
                log.debug("%s:%s to be deleted: %s" % (name, tag, delta))
                old_tags.append("%s:%s" % (name, tag))
            else:
                log.debug("%s:%s won't be deleted: %s" % (name, tag, delta))

    if len(whitelisted):
        log.info("%s tags protected by whitelist." % len(whitelisted))

    if len(old_tags):
        log.info("%s tags will be deleted." % len(old_tags))
    else:
        log.info("Did not find any tags to delete.")
        sys.exit(0)

    failed = []
    for old_tag in old_tags:
        # Delete tags
        cmd = "oc delete -n %s istag %s" % (args.namespace, old_tag)
        success, output = run_command(cmd, log, confirm=args.confirm)
        if not success:
            failed.append(old_tag)

    if len(failed):
        log.error("%s tags were not deleted successfully." % len(failed))
        for tag in failed:
            log.error(tag)

    log.info("Finished.")
    sys.exit(0)


if __name__ == "__main__":
    main()
