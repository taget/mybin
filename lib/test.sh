#!/bin/bash
# created by Jimmy @ 2013.4.1
set -x

. ./common.sh

# test real path
realpath=$(_get_real_path $0)
echo ${realpath}

