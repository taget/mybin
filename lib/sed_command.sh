#/bin/bash

#sed command example
#
#
#--------------------------#
#1. remove_line_number in a file
#
#bash-4.1$ cat tmp 
# 1065  git add scripts/
# 1066  git commit -am "Add-igor-helper-scripts" --signoff
# 1067  git add tests/
# 1068  git commit -am "Add-igor-test-plan-suite-for-itme-and-frobisher" --signoff
# 1070  git add confs/
# 1071  git commit -am "Add-configuration-files-for-igord" --signoff
# 1072  git add README 
# 1073  git commit -am "Add-README-file-for-frobisher_bvt-repository" --signoff


function remove_line_number()
{    
    filename=$1
    sed s/^[[:space:]][0-9]*[[:space:]]// $filename
}

#------------------------------------#
#2. remove # in a file

function remove_comment()
{
   filename=$1
   sed s/^#// $filename
}
