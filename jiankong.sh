#!/bin/bash
USER="rsynccheck"
DATABASE="rsync_check"
PASSWD="jwkj123"
checkdate=$(date +%F\ %T)
checkIP="219.138.135.11"
PORT="11711"

#监控cpu系统负载
#IP=`ifconfig em1 | grep "inet addr" | cut -f 2 -d ":" | cut -f 1 -d " "` 
IP=`/sbin/ifconfig em1 | grep inet | grep -v '127.0.0.1' |  awk '{ print $2}' | cut -f 2 -d : | awk '{ print $1;exit;}'`
mysql -h$checkIP -u $USER -P$PORT -p$PASSWD $DATABASE << EOF
        delete from rsync_jiankong where ipname='$IP';
EOF

cpu_num=`grep -c 'model name' /proc/cpuinfo`
count_uptime=`uptime |wc -w`
load_15=`uptime | awk '{print $'$count_uptime'}'`
average_load=`echo "scale=2;a=$load_15/$cpu_num;if(length(a)==scale(a)) print 0;print a" | bc`  
average_int=`echo $average_load | cut -f 1 -d "."`  
load_warn=0.70  
if [ $average_int -gt 0 ]
then
echo "$IP服务器单个核心15分钟的平均负载为$average_load，超过警戒值1.0，请立即处理！！！$(date +%Y%m%d/%H:%M:%S)" 
else
echo "$IP服务器单个核心15分钟的平均负载值为$average_load,负载正常   $(date +%Y%m%d/%H:%M:%S)"
fi

mysql -h$checkIP -u $USER -P$PORT -p$PASSWD $DATABASE << EOF
     INSERT INTO rsync_jiankong(ipname,jiankong,jkname,jkresult) VALUES('$IP',4,'CPU负载监控','$average_load');
     INSERT INTO rsync_jiankong_history(ipname,jiankong,jkname,jkresult,jkdate) VALUES('$IP',4,'CPU负载监控','$average_load','$checkdate');
EOF


#监控cpu使用率
#cpu_idle=`top -b -n 1 | grep Cpu | awk '{print $5}' | cut -f 1 -d "."`  
cpu_per=`top -b -n 1 | grep Cpu | awk '{print $2}'| cut -f 1 -d "."`
if [ $cpu_per -lt 80 ]
then
echo  "$IP服务器cpu使用$cpu_per%,使用率正常"

else
echo "$IP服务器cpu使用$cpu_per%,使用率已经超过80%,请及时处理。"

fi

mysql -h$checkIP -u $USER -P$PORT -p$PASSWD $DATABASE << EOF
     INSERT INTO rsync_jiankong(ipname,jiankong,jkname,jkresult) VALUES('$IP',2,'CPU使用率','$cpu_per%');
     INSERT INTO rsync_jiankong_history(ipname,jiankong,jkname,jkresult,jkdate) VALUES('$IP',2,'CPU使用率','$cpu_per%','$checkdate');
EOF

#监控交换分区
swap_total=`free -m | grep Swap | awk '{print  $2}'`
swap_free=`free -m | grep Swap | awk '{print  $4}'`

swap_used=`free -m | grep Swap | awk '{print  $3}'`

if [ $swap_used -ne 0 ]
then
swap_per=0`echo "scale=2;$swap_free/$swap_total" | bc`
swap_warn=0.20
swap_now=`expr $swap_per \> $swap_warn`
if [ $swap_now -eq 0 ]
then
    echo "$IP服务器swap交换分区只剩下 $swap_free M 未使用，剩余不足20%，使用率$swap_per已经超过80%，请及时处理。"
else
    echo "$IP服务器swap交换分区剩下 $swap_free M未使用，使用率$swap_per正常"
  fi

else
     echo "$IP服务器交换分区未使用"  
fi

#监控内存使用
mem_total=`free -m | grep Mem | awk '{print  $2}'`
mem_free=`free -m | grep Mem | awk '{print  $4}'`
mem_buffers=`free -m | grep Mem | awk '{print  $6}'`
mem_cached=`free -m | grep Mem | awk '{print  $7}'`

mem_used=`expr $mem_total - $mem_free - $mem_buffers - $mem_cached`

if [ $mem_used -ne 0 ]
then
mem_per=0`echo "scale=2;$mem_used/$mem_total" | bc`
mem_warn=0.80
mem_now=`expr $mem_per \> $mem_warn`
if [ $mem_now -ne 0 ]
then
    echo "$IP服务器内存已使用 $mem_used M ，剩余不足20%，使用率$mem_per已经超过80%，请及时处理。"
else
    echo "$IP服务器内存已使用 $mem_used M，使用率$mem_per正常"
  fi

else
     echo "$IP服务器内存未使用"
fi

mysql -h$checkIP -u $USER -P$PORT -p$PASSWD $DATABASE << EOF
     INSERT INTO rsync_jiankong(ipname,jiankong,jkname,jkresult) VALUES('$IP',3,'内存使用率','$mem_per');
     INSERT INTO rsync_jiankong_history(ipname,jiankong,jkname,jkresult,jkdate) VALUES('$IP',3,'内存使用率','$mem_per','$checkdate');
EOF



#监控磁盘空间
DISKINFO=`df -h | grep /| grep % | awk '{print $(NF-1)$NF}'` 
for info in $DISKINFO
do
     disk=${info##*%}
     per=${info%%%*}
     if [ ${per} -gt 80 ]
     then
		echo "$IP服务器 $disk分区 使用率$per%已经超过80%,请及时处理。"
     else
     		echo "$IP服务器 $disk分区 使用率为$per%,使用率正常"
     fi

mysql -h$checkIP -u $USER -P$PORT -p$PASSWD $DATABASE << EOF
     INSERT INTO rsync_jiankong(ipname,jiankong,jkname,jkresult) VALUES('$IP',1,'$disk分区使用率','$per%');
     INSERT INTO rsync_jiankong_history(ipname,jiankong,jkname,jkresult,jkdate) VALUES('$IP',1,'$disk分区使用率','$per%','$checkdate');

EOF
done


#监控登录用户数
users=`uptime |awk '{print $7}'`
if [ $users -gt 2 ]
then

echo "$IP服务器用户数已经达到$users个，请及时处理。"

else

   echo "$IP服务器当前登录用户为$users个，情况正常"
fi
###############################################################################

