# Copyright 2015 Intel, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
import os
import sys

from glob import glob
from yaml import load
import testtools

TEMPLATE_PATH = './'


class TestTemplate(testtools.TestCase):

    def test_template_yaml(self):
        for yml in [y for x in os.walk(TEMPLATE_PATH)
                    for y in glob(os.path.join(x[0], '*.yaml'))]:
            with open(yml, 'r') as f:
                yml_contents = f.read()
                try:
                    load(yml_contents)
                except Exception:
                    error_msg = "file: %s: %s" % (yml, sys.exc_info()[1])
                    self.fail(error_msg)
