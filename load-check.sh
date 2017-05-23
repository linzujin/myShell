#!/bin/bash

HOST="219.138.135.11"
PORT="11711"
USER="rsynccheck"
DATABASE="rsync_check"
TABLE="rsync_result"
PASSWD="jwkj123"

#获取IP
IP=`/sbin/ifconfig eth1 | grep inet | grep -v '127.0.0.1' |  awk '{ print $2}' | cut -f 2 -d : | awk '{ print $1;exit;}'`
#一分钟负载情况
ONE=`uptime | awk -F ':' '{print $NF}' | awk -F ',' '{print $1}' | sed s/[[:space:]]//g`
#五分钟负载情况
FIVE=`uptime | awk -F ':' '{print $NF}' | awk -F ',' '{print $2}' | sed s/[[:space:]]//g`
#十五分钟负载情况
FIFT=`uptime | awk -F ':' '{print $NF}' | awk -F ',' '{print $3}' | sed s/[[:space:]]//g`

US=`/usr/bin/top  -b -d 1 -n 2 |grep Cpu | cut -d "," -f 1 | cut -d ":" -f 2 | awk -F '%' '{print $1}' | sed s/[[:space:]]//g | sed -n "2, 1p" | sed 's/us//g'`
SY=`/usr/bin/top  -b -d 1 -n 2 |grep Cpu | cut -d "," -f 2 | cut -d ":" -f 2 | awk -F '%' '{print $1}' | sed s/[[:space:]]//g | sed -n "2, 1p" | sed 's/sy//g'`

TODAY=`date -d "0 day" +"%Y-%m-%d %H:%M:%S"`

#数据入库
mysql -h $HOST -P $PORT -u $USER $DATABASE -p$PASSWD -se "insert into rsync_serverload(ip,one_minutes,five_minutes,fifteen_minutes,uscpu,sycpu,ctime) values('$IP','$ONE','$FIVE','$FIFT','$US','$SY','$TODAY');";
