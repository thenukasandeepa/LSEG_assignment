#!/bin/bash

ssh <web_user>@<web_server_ip> tar cvpf /home/thenuka/logs/logfile.tar -C /home/thenuka/logs/ . --remove-files

rsync -avz --remove-source-files <web_user>@<web_server_ip>:/home/thenuka/logs/logfile.tar .

aws s3 mv logfile.tar s3://lseg.s3
if [ $? == 0 ] ; then
  echo 'uploaded successfuly'
else
  echo 'send an error mail: uploading error'
  aws ses send-email --from <sender>@gmail.com --to <receiver>@gmail.com --subject "lseg script2" --text "uploading error to the s3 bucket"
fi
