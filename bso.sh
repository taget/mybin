#!/usr/bin/expect -f
# This script will try to telnet $1
#
set ip [lindex $argv 0]
set username "$env(IBMUSER)"
set password "$env(IBMPASSWORD)"

#login 
spawn telnet $ip
set timeout 300
expect "Username: "
send "$username\r"
expect "Password: "
send "$password\r"
expect eof
exit

