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

function _get_str_len()
{
    local str=$1
    len=$(expr length ${str})
    echo ${len}
    return 0
}

# get the package name
# _get_package_name python-cinderclient-1.0.9.tar.gz
# _get_package_name python-cinderclient-1.0.tar.gz
# _get_package_name python-cinderclient-1.0.whel
# return python-cinderclient
function _get_package_name()
{
    local str=$1
    dir=$(echo $str | sed 's/[-][0-9.]*\.[a-z]*\.[a-z]*$//')
    echo $dir
}

# given a string which is the variable name
# return the real variable value
# var='this is the real value'
# var_name='var'
# given you var_name(actually, a string)
# return the value of var_name

function get_real_var_name()
{
    local var=$1
    echo $@!var}

    # or
    # eval ret=\$$var
}


# given a started ip
# compute a list of ip address
# follow result would be
# NO_PROXY=192.168.0.3,192.168.0.4,192.168.0.5,192.168.0.6

NODE_COUNT="3"
SWARM_MASTER_IP="192.168.0.3"
NO_PROXY=$SWARM_MASTER_IP

function compute() {
   local i=$NODE_COUNT
   tmp_ip=$(echo $SWARM_MASTER_IP | awk -F. '{print $4}')
   ip_prefix=$(echo $SWARM_MASTER_IP | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.')
   for (( ; ; )) do
       if [[ $i -eq 0 ]];
       then
           break
       fi
       i=$(($i - 1))
       tmp_ip=$(($tmp_ip + 1))
       NO_PROXY=${NO_PROXY}","${ip_prefix}${tmp_ip}
   done
}

compute

