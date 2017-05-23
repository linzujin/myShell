#!/bin/bash

HOST="219.138.135.11"
PORT="11711"
USER="rsynccheck"
DATABASE="rsync_check"
TABLE="rsync_result"
PASSWD="jwkj123"

TODAY=`date -d "0 day" +"%Y-%m-%d %H:%M:%S"`
#获取IP
IP=`/sbin/ifconfig eth1 | grep inet | grep -v '127.0.0.1' |  awk '{ print $2}' | cut -f 2 -d : | awk '{ print $1;exit;}'`
#获取磁盘信息
DISKINFO=`df -m | grep /| grep % | awk '{print $(NF-2)"/"$(NF-1)$NF}'`
value=''
str=''


for info in $DISKINFO
do
     disk=${info##*%}
     perarr=${info%%%*}
     per=${perarr##*/}
     num=${perarr%/*}
     num=$[num/1024]
     if [ ${per} -gt 80 ]
     then
	value=$value",('"$IP"','"${disk}"','"${per}"','"${num}"','"${TODAY}"')"
	str=$str"
	 The "$IP" server ("${disk}") disk usage: "${per}"%"
    fi
done


value=${value#*,}

if [ -n "$value" ]
then

#数据入库
mysql -h $HOST -P $PORT -u $USER $DATABASE -p$PASSWD -se "insert into rsync_diskload(ip,disk,percent,capacity,addtime) values $value;";


echo $str | mail -s " Server disk usage" linzujin@juwang.com.cn
echo $str | mail -s " Server disk usage" dingwengeng@juwang.com.cn

else

echo "Congratulations, the system is in good condition..."

fi
