#!/usr/bin/expect -f
# This script will reboot the os by given $1 immip, $2 username, $3 password
set ip [lindex $argv 0]
set username [lindex "qiaoly@cn.ibm.com"]
set password [lindex "jimmy@ibm"]

#login 
spawn telnet $ip
set timeout 300
expect "Username: "
send "$username\r"
expect "Password: "
send "$password\r"
expect eof
exit

