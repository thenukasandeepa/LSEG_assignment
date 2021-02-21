#!/bin/bash
ssh <web_user>@<web_server_ip> "bash -s" << EOF
current_time=$(date "+%Y.%m.%d_%H.%M.%S")
logName=$user/logs/$current_time.log

ps cax | grep httpd>$logName
if [ $? -eq 0 ]; then
  echo "Process is running."|tee -a $logName
  httpstat="service running"
else
  echo "Process is not running."|tee -a $logName
  sudo systemctl start httpd
  if [ $? -eq 0 ]; then
        echo "started the process"|tee -a $logName
        httpstat="service not running: started"
  else
        echo "error:starting process"|tee -a $logName
        httpstat="service not running: can not start"
        aws ses send-email --from <sender>@gmail.com --to <receiver>@gmail.com --subject "lseg script1" --text "uploading error to the s3 bucket"
  fi

fi

url="http://3.140.201.129/"
content="$(curl -sLI "$url" | grep HTTP/1.1 | tail -1 | awk {'print $2'})"
if [ ! -z $content ] && [ $content -eq 200 ]
then
  echo "serving the expected content"|tee -a $logName
else
  echo "error:not serving the expected content"|tee -a $logName
  aws ses send-email --from <sender>@gmail.com --to <receiver>@gmail.com --subject "lseg script1 status" --text "error in getting the content : $content"
fi

mysql -h <endpoint> -P 3306 -u <username> -p<password> table_name -e "CALL insert_logstatus('$httpstat',$content,'$current_time');">> $logName 2>&1

EOF