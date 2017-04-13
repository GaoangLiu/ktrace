#!/bin/bash
# upload important files to server 

echo ":...uploading $1 to folder" 
if [ ! $1 ]; then 
    echo ":...you'll have to specify a file before using this script" 
    exit 0 
fi 

scp -r $1 gaoang@192.168.1.27:/home/gaoang/ktrace/
