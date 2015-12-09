#!/bin/bash
set -x
heat stack-create -f lmcluster.yaml -e local.yaml my-lm-cluster

heat output-list my-lm-cluster
