#!/bin/bash


if [ $# -gt 0 ]; then
	scp taget@9.181.129.59:/home/taget/rhevh-auto/output/*$1 ./
else
	scp -r taget@9.181.129.59:/home/taget/rhevh-auto/rhevh/rhevh-recipe/recipes/sdmc/doc ./
fi
