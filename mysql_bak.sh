#!/bin/sh
#written by linzujin@juwang.com.cn

USER="root"
PASSWORD=""
DATABASE="test"
TARGETIP="192.168.1.12"
MYSQLTARGETDIR="/data/192.168.1.12/mysql-bak/"

DATE=`date +\%Y\%m\%d\%H\%M`

WEBDIR="/home/wwwroot/ywsys"

echo "---------------备份数据开始------------------------"
mysqldump -u$USER -p$PASSWORD --lock_tables=false -f --flush-privileges  --triggers -R --events -B $DATABASE | gzip > $WEBDIR"/mysqldata/"${DATABASE}${DATE}.sql.gz
echo "---------------同步数据库开始----------------------"
scp $WEBDIR"/mysqldata/"${DATABASE}${DATE}.sql.gz $USER@$TARGETIP:$MYSQLTARGETDIR
rm  $WEBDIR"/mysqldata/"${DATABASE}${DATE}.sql.gz


