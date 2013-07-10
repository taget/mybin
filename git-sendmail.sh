#!/bin/bash

echo $@

git send-email --smtp-server ap.relay.ibm.com "$@" --from taget@linux.vnet.ibm.com --to frobisher@lists.linux.ibm.com


#git send-email --smtp-server ap.relay.ibm.com --smtp-debug 1 "$@" --from taget@linux.vnet.ibm.com --to taget@linux.vnet.ibm.com


#git send-email --smtp-server ap.relay.ibm.com --smtp-debug 1 "$@" --from taget@linux.vnet.ibm.com --to rhevh-blue@lists.linux.ibm.com --to frobisher@lists.linux.ibm.com
