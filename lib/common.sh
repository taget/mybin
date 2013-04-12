# created by Jimmy @ 2013.4.1

_dirname="/usr/bin/dirname"
_basename="/bin/basename"


#get the real path of a file
function _get_real_path()
{
    PATH=$1
    REAL_PATH=$(cd "$(${_dirname} ${PATH})" && pwd)/$(${_basename} ${PATH})
    echo ${REAL_PATH}
    return 0
}

