# created by Jimmy @ 2013.4.1

_dirname="/usr/bin/dirname"
_basename="/bin/basename"


#get the real path of a file
#_get_real_path /home/taget
#return /home/taget
function _get_real_path()
{
    local PATH=$1
    local REAL_PATH=$(cd "$(${_dirname} ${PATH})" && pwd)/$(${_basename} ${PATH})
    echo ${REAL_PATH}
    return 0
}

#get 
#_get_field "a-b-cc-d" 2 "-"
#return b
function _get_field
{
   local text=$1
   local pos=$2
   local delimiter=$3
   local field=$(echo ${text} | cut -d ${delimiter} -f${pos})
   echo ${field}
   return 0
}

