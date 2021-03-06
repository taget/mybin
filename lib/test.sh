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

# test _get_str_len
len=$(_get_str_len "pure-1.2.33.iso")

testiso=abslfjisf-fef-fefef-fefe.1.2.33.test.iso
iso_len=$(expr length ${testiso})
    if [[ ${iso_len} -gt 20 ]]; then
        short_iso="pure-"$(echo ${testiso} |\
                  egrep -o [0-9]+.[0-9]+.[0-9]+).test.iso
    fi
