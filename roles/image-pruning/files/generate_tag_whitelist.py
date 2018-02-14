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
import json
import logging
import logging.config
import os
import pip
import shlex
import subprocess
import virtualenv
import yaml

CLIENT = "git+https://github.com/softwarefactory-project/dlrnapi_client"
URL = "https://trunk.rdoproject.org"
VENV = "/var/tmp/dlrnapi_client"
BUILDERS = [
    "api-centos-master-uc",
    "api-centos-pike"
]
SYMLINKS = [
    "latest",
    "current-tripleo",
    "current-tripleo-rdo",
    "current-tripleo-rdo-internal",
    "current-passed-ci"
]


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
    parser.add_argument("--debug", help="Enable debug logging",
                        action="store_true")
    args = parser.parse_args()
    return args


def run_command(command, log, fatal=False):
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


def setup_dlrnapi_client(log):
    if not os.path.exists(VENV):
        log.info("Creating virtualenv: %s" % VENV)
        virtualenv.create_environment(VENV)

    activate_this = os.path.join(VENV, "bin/activate_this.py")
    log.debug("Sourcing venv: %s" % activate_this)
    execfile(activate_this, dict(__file__=activate_this))

    try:
        import dlrnapi_client
    except ImportError:
        log.info("Installing dlrnapi_client")
        # Not sure why pip.main doesn't work
        
        import pdb; pdb.set_trace()
        pip.main(["install", CLIENT])


def main():
    args = get_args()
    level = "DEBUG" if args.debug else "INFO"
    setup_logging(level)
    log = logging.getLogger(os.path.basename(__file__))
    log.debug("Arguments: %s" % json.dumps(args.__dict__))

    setup_dlrnapi_client(log)

    whitelist = []
    for builder in BUILDERS:
        endpoint = "%s/%s" % (URL, builder)
        for symlink in SYMLINKS:
            cmd = "dlrnapi --url %s promotion-get --promote-name %s" % (
                endpoint, symlink
            )
            promotions = run_command(cmd, log)
            try:
                promotions = json.loads(promotions)
                if promotions:
                    commit_hash = promotions[0]["distro_hash"]
                    distro_hash = promotions[0]["distro_hash"]
                    repo = "%s_%s" % (commit_hash, distro_hash[:8])
                    log.info("Adding %s to whitelist" % repo)
                    whitelist.append(repo)
            except Exception as e:
                log.error(str(e))
                raise e
    print(whitelist)


if __name__ == "__main__":
    main()
