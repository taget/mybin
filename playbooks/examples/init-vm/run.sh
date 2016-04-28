#!/bin/bash

ansible-playbook -i host vm-init.yml -vvvv $*
