#!/usr/bin/env python

# send a curl http request to get token id from keystone first.
# then send a curl request to api server, support post/get
# ps : change get_token_id 's default url to adopt your keystone service
#      change the default password in get_token_id

import sys
import subprocess
from subprocess import Popen, PIPE, STDOUT
from json import *


def exec_command(argv):
    """
    This function executes a given shell command.
    """

    try:
        p = Popen(argv, shell=True, stdout=PIPE, stderr=PIPE)
        out, err = p.communicate()
        rc = p.returncode
    except:
        print traceback.format_exc()

    return (rc, out, err)


def str_2_json(http_resp):
    s = http_resp[http_resp.find('{') :]
    return JSONDecoder().decode(s)

def get_token_id(url = 'http://cloudcontroller:5000/v2.0/tokens'):
    cmd = '''
curl -i '%s' -X POST -H "Accept: application/json" -H "Content-Type: application/json" -H "User-Agent: python-novaclient" -d '{"auth": {"tenantName": "admin", "passwordCredentials": {"username": "admin", "password": "123"}}}'
''' % url

    (rc,out,err) = exec_command(cmd)
    return str_2_json(out)['access']['token']['id']


def exec_url(url = 'http://cloudcontroller:8774/v3/servers/detail', id=None, post=None):
    if id is None:
        print "id is none"
        raise
    cmd = '''
curl -i '%s' -X GET -H "Accept: application/json" -H "User-Agent: python-novaclient" -H "X-Auth-Project-Id: admin" -H "X-Auth-Token: %s"
''' % (url, id)
    # post url
    if post:
        cmd = '''
curl -i '%s' -X PUT -H "Accept: application/json" -H "Content-Type: application/json" -H "User-Agent: python-novaclient" -H "X-Auth-Project-Id: admin" -H "X-Auth-Token: %s" -d '%s'
''' % (url, id , post)
        
    print '-------'
    print cmd
    print '-------'
    (rc,out,err) = exec_command(cmd)
    print (rc, out ,err)



def usage():
    print '''usage:
python ./test.py http_req [post_data]
ps: change the default password in get_token_id in test.py
'''

if len(sys.argv) < 2 or len(sys.argv) > 3:
    usage()
    exit(1)

http_req = sys.argv[1]

if len(sys.argv) == 3:
    post = sys.argv[2]
else:
    post = None

id = get_token_id()

print ("http_req : %s") % http_req
print ("post : %s") % post
try:
    exec_url(url = http_req, id = id, post = post)
except:
    raise

