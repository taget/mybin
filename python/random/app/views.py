# Copyright 2015 Eli Qiao
# Administrator of the National Aeronautics and Space Administration.
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


from app import app
from app import manager

from flask import abort
from flask import jsonify
from flask import request
from flask import make_response

random_manager = manager.Manager()

@app.route('/')
@app.route('/index')
def index():
    print app.app_context()
    return "hello world!"

#create a random code with a timeout window
@app.route('/random', methods=['POST'])
def create_random():
    print request.json
    if not request.json or not 'length' in request.json:
        abort(400)
    req = request.json
    length = req.get('length')
    timeout = req.get('time_out', 10)
    code = random_manager.create_random(length, timeout=timeout)

    return jsonify({'code': code}), 201

#verify random code exist
@app.route('/random/<string:code>', methods=['GET'])
def get_random(code):
    code = random_manager.get_random(code)
    return jsonify({'code': code})

@app.errorhandler(404)
def not_found(error):
    return make_response("error, not found", 404)
