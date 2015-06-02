from app import random_code
from app import memorycache

import json
import uuid


class Manager(object):

    def __init__(self):
        self.mc = memorycache.get_client()

    def create_random(self, length, timeout=10):

        code = random_code.get_random_str(length)
        val = int(uuid.uuid4()) % 100000000000000
        data_dict = {'uuid': val}
        data = json.dumps(data_dict)
        self.mc.set(code, data, timeout)
        return code

    def get_random(self, code):
        code_find = self.mc.get(code)
        return code_find

    def delete_random(self, code):
        self.mc.delete(code)

    def list_random(self):
        pass
