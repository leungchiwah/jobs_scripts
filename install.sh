#!/bin/bash

function MYSQL_INSTALL {

LI=`rpm -qa|grep libaio-devel |wc -l`
if [ $LI -eq 0 ];then
	yum -y install libaio-devel &>/dev/null
	if [ $? -ne 0 ];then
		echo " yum libaio fail .."
		exit
	fi
fi

MA=`rpm -qa |grep mariadb`
MA_NUM=`rpm -qa |grep mariadb|wc -l`
if [ $MA_NUM -eq 1 ];then
	yum remove $MA -y &>/dev/null
fi

tar xf /mysql_install/packages/mysql-5.7.26-linux-glibc2.12-x86_64.tar.gz -C /usr/local/
if [ -d /usr/local/mysql-5.7.26-linux-glibc2.12-x86_64 ];then
	mv /usr/local/mysql-5.7.26-linux-glibc2.12-x86_64 /usr/local/mysql
else
	echo "解压失败...."
	exit
fi

USER=`grep "mysql" /etc/passwd |wc -l`
if [ $USER -eq 0 ];then
	useradd mysql -s /sbin/nologin -M
else
	echo " mysql 用户已存在.."
fi

if [ ! -d /data ];then
	mkdir /data
else
	echo "/data is exist "
fi

chown -R mysql.mysql /usr/local/mysql
chown -R mysql.mysql /data

#ln -s /usr/local/mysql/bin/* /usr/local/bin/

#在子shell里面执行不了source
echo "export PATH=/usr/local/mysql/bin:$PATH" >>/etc/profile
source /etc/profile &>/dev/null
which mysql &>/dev/null
if [ $? -eq 0 ];then
	echo "mysql安装成功..."
else	
	echo "设置mysql变量失败..."
fi
}

function Example {
clear

read -p "input example port: " port
read -p "input example server_id: " id

mkdir /data/$port/{data,binlog} -p

cat >/data/$port/my.cnf<<EOF
[mysqld]
basedir=/usr/local/mysql/
datadir=/data/$port/data
socket=/data/$port/mysql.sock
log_error=/data/$port/mysql.log
server_id=$id
port=$port
secure-file-priv=/tmp
autocommit=0
log_bin=/data/$port/binlog/mysql-bin
binlog_format=row
gtid-mode=on
enforce-gtid-consistency=true
log-slave-updates=1
[mysql]
prompt=$port [\d]>
EOF

chown -R mysql.mysql /data/$port

mysqld --initialize-insecure --user=mysql --basedir=/usr/local/mysql --datadir=/data/$port/data &>/dev/null

if [ -e /etc/systemd/system/mysqld$port.service ];then
	rm -f /etc/systemd/system/mysqld$port.service
fi
 
cat >/etc/systemd/system/mysqld$port.service<<EOF
[Unit]
Description=MySQL Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.htmlAfter=network.target
After=syslog.target
[Install]
WantedBy=multi-user.target
[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/data/$port/my.cnf
LimitNOFILE = 5000
EOF

echo "example is SUCCESS ..."
sleep 1
echo
echo "please  source /etc/profile  ...."
}

function Example_NUM {
MM=`ls -A /data |wc -l`
if [ $MM -ne 0 ];then
	echo -e "本机存在的MySQL实例: \n`ls -A /data`"
else
	echo -e "本机不存在实例"
fi


}



#systemctl enable mysqld$port.service
#systemctl start mysqld$port.service

#mysql -S /data/$port/mysql.sock -e "select @@server_id"
#mysql -S /data/$port/mysql.sock -e "select @@port"
#mysql -p $port -e "grant all on *.* to root@'localhost' identified by 'guanxi520'"


function MENU {
clear

cat << EOF
----------------------------------------
|************Menu Home Page ************|
----------------------------------------
`echo -e "\t\033[35m 1)安装MySQL\033[0m"`
`echo -e "\t\033[35m 2)创建一个实例\033[0m"`
`echo -e "\t\033[35m 3)安装MySQL并创建实例\033[0m"`
`echo -e "\t\033[35m 4)查看本机实例\033[0m"`
`echo -e "\t\033[35m 5)Quit\033[0m"`
EOF
}

function RUN {
while true
   do
	MENU
	read -p "input you num：" num
	case $num in
		1)MYSQL_INSTALL;exit;;
		2)Example;exit;;
		3)MYSQL_INSTALL;Example;exit;;
		4)Example_NUM;exit;;
		5)exit;;
		*)MENU;;
	esac
done
}

RUN






