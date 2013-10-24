#!/bin/bash
echo "git am patches/*"
#find the am failed patches
#move them to cannotapply
#git am --abort
#re am patches/*

while true;
do
    out=$(git am patches/*)
    res=$?
    if [[ ${res} -eq 0 ]]; then
        echo "no error!"
        break
    fi
    echo "error !"
    tmp=$(echo "${out}" | tail -n 6 | head -n 1 | awk -F: '{print $2}')
    tmp=${tmp#" "}
    echo "${tmp}"
    name=$(find patches/ | xargs grep "${tmp}"| awk -F: '{print $1}')
    if [[ $? -eq 0 ]]; then
       echo "move ${name} to cannotapply"
       mv ${name} cannotapply/
    fi
    git am --abort
done 

