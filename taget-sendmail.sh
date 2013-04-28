#!/bin/bash

echo $1

git send-email --confirm auto --smtp-server ap.relay.ibm.com "$1" --from taget@linux.vnet.ibm.com --to taget@163.com
