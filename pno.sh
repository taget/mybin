#!/bin/bash

APPLIST=(
	#"ibm-notes8"
	"thunderbird"
	"pidgin"
	"goldendict"
)
ps -ef | grep notes | grep -v grep | awk '{print $2}' | xargs kill -9 
/usr/bin/ibm-notes8 &
for app in "${APPLIST[@]}"; do
	ps -ef | grep $app | grep -v grep | awk '{print $2}'| xargs kill -9	
	/usr/bin/$app &
	echo "$app done!"
done

echo "exit"
exit
