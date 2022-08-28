#!/bin/bash

rpm -q wget || yum install -y wget
yum install gcc automake autoconf libtool make
yum install -y gcc openldap-devel pam-devel openssl-devel
wget -N --no-check-certificate https://github.com/siemenstutorials/Socks5Go/releases/download/v1/ss5-3.8.9-8.tar.gz
tar -vzx -f ss5-3.8.9-8.tar.gz
cd ss5-3.8.9/
./configure
make
make install
chmod a+x /etc/init.d/ss5

#Check server ip

public_ip=${VPN_PUBLIC_IP:-''}
check_ip "$public_ip" || public_ip=$(dig @resolver1.opendns.com -t A -4 myip.opendns.com +short)
check_ip "$public_ip" || public_ip=$(wget -t 3 -T 15 -qO- http://ipv4.icanhazip.com)
check_ip "$public_ip" || exiterr "Cannot detect this server's public IP. Define it as variable 'VPN_PUBLIC_IP' and re-run this script."

#用户登陆设置
read -p "Please input Username(Default Username:s1)：" Username
[ -z "${Username}" ] && Username=s1
echo "Username = ${Username}"
read -p "Please input Password(Default UserPassword:jxyt668)：" UserPasswd
[ -z "${UserPasswd}" ] && UserPasswd=jxyt668
echo "UserPasswd = ${UserPasswd}"
read -p "Please input Port(Default Port:1080)：" set_port
[ -z "${set_port}" ] && set_port=1080
echo "set_port = ${set_port}"

#指定端口连接设置
pf=/etc/init.d/ss5
sed -i '6c export SS5_SOCKS_PORT=1080' $pf
sed -i '7c export SS5_SOCKS_USER=root' $pf

#用户登陆权限设置
confFile=/etc/opt/ss5/ss5.conf
echo -e $Username $UserPasswd >> /etc/opt/ss5/ss5.passwd
sed -i "s|1080|${set_port}|" $pf
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

echo -e "安装完成SOCKS5连接信息如下:"
echo "————————————————————————————————"
echo "服务器IP: " ${public_ip}
echo "用户名: " ${Username}
echo "密 码: " ${UserPasswd}
echo "端 口: " ${set_port}
echo "————————————————————————————————"
