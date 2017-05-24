#!/bin/bash
#Author:linzujin
#Desc:check nginx mysql php status ,if it is stop status ,then start
#Time:2016-12-21
#Email:linzujin@juwang.com.cn


ps aux | grep php-fpm  | grep -v grep

if [ $? -ne 0 ];then

/etc/init.d/php-fpm start

fi

ps aux | grep mysql | grep -v grep 

if [ $? -ne 0 ];then

/etc/init.d/mysql start

fi

ps aux | grep nginx | grep -v grep 

if [ $? -ne 0 ];then

/etc/init.d/nginx start

fi
