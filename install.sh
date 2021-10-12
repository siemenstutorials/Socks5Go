#!/bin/bash

rpm -q wget || yum install -y wget
yum install gcc automake autoconf libtool make
yum install -y gcc openldap-devel pam-devel openssl-devel
https://github.com/siemenstutorials/Socks5Go/releases/download/v1/ss5-3.8.9-8.tar.gz
tar -vzx -f ss5-3.8.9-8.tar.gz
cd ss5-3.8.9/
./configure
make
make install
chmod a+x /etc/init.d/ss5

#用户登陆设置
read -p "Please input Username(Default Username:s1)：" Username
[ -z "${Username}" ] && Username=s1
echo "Username = ${Username}"
read -p "Please input Password(Default UserPassword:jxyt668)：" UserPasswd
[ -z "${UserPasswd}" ] && UserPasswd=jxyt668
echo "UserPasswd = ${UserPasswd}"
confFile=/etc/opt/ss5/ss5.conf
echo -e $Username $UserPasswd >> /etc/opt/ss5/ss5.passwd
sed -i '87c auth    0.0.0.0/0               -               u' $confFile
sed -i '203c permit u	0.0.0.0/0	-	0.0.0.0/0	-	-	-	-	-' $confFile

#开机启动
chmod +x /etc/init.d/ss5
chkconfig --add ss5
chkconfig --level 345 ss5 on
confFile=/etc/rc.d/init.d/ss5
sed -i '/echo -n "Starting ss5... "/a if [ ! -d "/var/run/ss5/" ];then mkdir /var/run/ss5/; fi' $confFile
sed -i '54c rm -rf /var/run/ss5/' $confFile
sed -i '18c [[ ${NETWORKING} = "no" ]] && exit 0' $confFile

#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" "/etc/selinux/config"

#安装完成
service ss5 stop && service ss5 restart
echo "Socks5安装完成" && service ss5 status
echo "默认用户名: "${Username}
echo "默认密码  : "${UserPasswd}
echo "默认端口  : "1080
