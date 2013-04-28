#!/bin/bash
# created by Jimmy @ 2013.4.1
set -x

. ./common.sh
. ./sed_command.sh

# test real path
realpath=$(_get_real_path $0)
echo ${realpath}

filed=$(_get_field "a-b-cc-d" 3 "-")
echo ${filed}

# test remove line number
remove_line_number ./tmp
