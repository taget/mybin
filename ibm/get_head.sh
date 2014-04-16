#!/bin/bash

# give a commit id ,
# return tag(s) if the tag on that commit id.
function get_tag_of_commit()
{
    commitid=$1
    git show-ref --tags | awk -v c=$1 '{if($1==c){print $2}}'
}

for repo in $(ls); do
    if [ -d $repo ]; then
        echo "repo: git://ltcphx.austin.ibm.com/frobisher/"${repo}".git"
        cd ${repo} #&& git pull
        commitid=$(git log --pretty=oneline -1)
        branch=$(git rev-parse --abbrev-ref HEAD)
        echo "Branch: "${branch}
        echo -ne "Tag(s): "
        get_tag_of_commit ${commitid}
        echo "HEAD: " ${commitid}
        cd ..
        echo "------------"
    fi
done
