#!/bin/bash
# set -x
#
# After modifing code, we need to do unit test/pep8 check
# This script will help you to save time.
# usage:
# ./test-py27-pep.sh nova.tests.unit.api.openstack.compute.contrlib.test_shelve
# or
#./test-py27-pep.sh, only to check pep8 for the changed files
if [[ -n "$@" ]]; then
    tox -e py27 "$@" | tee a.log
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        echo "unit test failed check a.log!"
        exit 1
    fi
fi

CHANGED_FILES=$(git status -s | awk '{if ($1 == "M"){print $2}}' | sed ':a;N;$!ba;s/\n/ /g')

# check pep8

if [[ -n "$CHANGED_FILES" ]]; then
    tox -e pep8 "$CHANGED_FILES" | tee b.log
    # git add
    if [ "${PIPESTATUS[0]}" -ne 0 ]; then
        echo "pep8 test failed check b.log!"
        exit 1
    fi

    git add "$CHANGED_FILES"
    git status
#    git commit --amend

else
    echo "nothing to be tested by pep8"
fi

