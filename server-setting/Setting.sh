#!/bin/sh
function EPEL_INSPECTION(){
	if [ "$(ls -l /etc/yum.repos.d/*epel* | wc -l)" -ne 5 ]
	then
		echo Make sure you properly proceeded option number 4. Epel Repository installation
		echo Epel Repository might not have been installed
	fi
}

## sysctl.conf ##
# sysctl.conf 설정 필요함
# /etc/sysctl.conf 하위 em1, em2 는 서버설치시 네트워크 이름에 따라 바꾸어야 함. ifconfig로 확인

function SYSCTL_CONF(){

	echo Start applying /etc/sysctl.conf...

	sleep 2

	cp /etc/sysctl.conf /etc/sysctl.conf.bk

	cat ./sysctlfile >> /etc/sysctl.conf

	echo Done
}
## END ##

## ulimite -a ##
# ulimit -a  설정변경

function LIMITS_CONF(){

	echo Start applying /etc/security/limits.conf...

	sleep 2

	cp /etc/security/limits.conf /etc/security/limits.conf.bk
	
	sed -i '/# End of file/d' /etc/security/limits.conf

	echo "Is this DB installation??[Y|N]"
	read A
	case $A in
	Y|y)
		sed '/php-fpm/d' ./limitconf >> /etc/security/limits.conf
	;;
	*)
		cat ./limitconf >> /etc/security/limits.conf
	;;
	esac
	echo \# End of file >> /etc/security/limits.conf

	echo Done
}

## END ##

# repo 8 추가 #

function EPEL_REPO(){
	
	echo Start installing...

	sleep 2	

	dnf install epel-release
	
	echo ---------- RESULT ----------
	ls -l /etc/yum.repos.d/*epel*


	echo $(ls -l /etc/yum.repos.d/*epel* | wc -l) / 5 are installed
	echo ------------ END -----------

}
## END ##

## php7.2, nginx 설치 ##
function NGINX_PHP72(){

	EPEL_INSPECTION

	echo Start removing old php, mariadb, httpd...

	sleep 2

	dnf erase php* httpd httpd-tools mariadb*

	echo Installing php72...

	dnf install php-devel php-snmp php php-mysqlnd php-ldap php-common php-pdo php-pecl-apcu-devel php-pecl-zip php-dba php-odbc php-pear php-xmlrpc php-json php-mbstring php-xml php-pecl-apcu php-gd php-intl php-enchant php-bcmath php-opcache php-cli php-fpm php-process

	echo Installing nginx...

	dnf install nginx

	echo Installing mongodb module...

	pecl install mongodb

	echo Done
	echo ---------- RESULT ----------
	rpm -qa | egrep 'nginx|php'

	echo $(rpm -qa | egrep 'nginx|php' | wc -l) / 33 are installed
	echo ------------ END -----------
}
## END ##-

## Composer 설치 ##
function COMPOSER(){

	EPEL_INSPECTION

	echo Start installing Composer..

	sleep 2

	echo ---------- RESULT ----------
	curl -sS https://getcomposer.org/installer | php
	mv composer.phar /usr/local/bin/composer

	if [ -z "$(ls -l /usr/local/bin/composer)" ];then
		echo Installation failed
	else
		echo -e $(ls -l /usr/local/bin/composer)\\nInstallation succeed
	fi
	echo ------------ END -----------
}
## END ##

## memcached , redis ##
# 레디스 최신 버젼을 사용한다.
function MEMCACHED_REDIS(){

	EPEL_INSPECTION

	echo Start installing...

	sleep 2

	dnf install memcached redis

#pecl 로 설치 및 php extension module 설정
	pecl install redis
	echo "; Enable redis extension module" > /etc/php.d/20-redis.ini
	echo "extension=redis.so" >> /etc/php.d/20-redis.ini

	echo ---------- RESULT ----------

	rpm -qa memcached redis

	ls -l /etc/php.d/20-redis.ini
	cat /etc/php.d/20-redis.ini

	echo are installed

	echo ------------ END -----------

	MR_ARRAY=("memcached" "redis")

	for i in ${MR_ARRAY[@]}
	do
		echo Would you like to start/enable $i? [y\|n]

		read A

		case $A in 
		y|Y)
			systemctl start $i
			systemctl enable $i
			systemctl status $i
			echo Done
		;;
		*)
			echo -e You chose No or irrelevant option\\nNot starting $i
		;;
		esac
	done

	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	echo '"never"' inputted in /sys/kernel/mm/transparent_hugepage/enabled
#echo /etc/rc.local >> "echo never > /sys/kernel/mm/transparent_hugepage/enabled"


	unset MR_ARRAY A
}
## END ##

## MariaDB 설치시  ##

function MARIADB(){

	EPEL_INSPECTION

#DB서버에는 mariaDB 등의 DB package와 glance, rsync, telnet, wget만 설치하면 된다.

	curl -LsS https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version=10.6.5 --skip-maxscale --skip-tools

	if [ -f /etc/yum.repos.d/mariadb.repo ]
	then 

		echo mariaDB.repo is copied

		echo Start installing MariaDB Server and client...

		sleep 2
	
		dnf install MariaDB-server MariaDB-client

		mkdir -p /etc/systemd/system/mariadb.service.d 
	
		echo <<EOF >> /etc/systemd/system/mariadb.service.d/limits.conf
[Service] 
LimitNOFILE=infinity
EOF
	
		ls -l /etc/systemd/system/mariadb.service.d/limits.conf
		systemctl daemon-reload
		echo Done
	
	# mysql /home 폴더로 이동 
		cp -rp /var/lib/mysql /home/mysql
		rm -rf /var/lib/mysql
		ln -s /home/mysql /var/lib/mysql
		chown -h mysql. /var/lib/mysql
	
		ls -l /home/mysql /var/lib/mysql

		echo Done
	
	# Prevent accessing /home, /root and /run/user
		if [ ! -z "/etc/systemd/system/multi-user.target.wants/mariadb.service" ]
		then 
			sed -i 's/ProtectHome=true/ProtectHome=false/' /usr/lib/systemd/system/mariadb.service
			ln -s /usr/lib/systemd/system/mariadb.service /etc/systemd/system/multi-user.target.wants/mariadb.service
		else
			sed -i 's/ProtectHome=true/ProtectHome=false/' /etc/systemd/system/multi-user.target.wants/mariadb.service
		fi
	
		grep ProtectHome /etc/systemd/system/multi-user.target.wants/mariadb.service

		echo "Is this for blogpay DB installation??[Y|N]"
	
		read A
	
		case $A in
		y|Y)
			mkdir /home/mysqltmp
			chown mysql. /home/mysqltmp

			mkdir /var/log/mariadb
			chown mysql. /var/log/mariadb

			mkdir /var/run/mariadb
			chown mysql. /var/run/mariadb

			cat ./mycnfserver > /etc/my.cnf.d/server.cnf
		;;
		*)
			echo "You chose No or irrelevant option"
		;;
		esac
	else
		echo Installing mariaDB.repo failed...!
	fi

	echo ---------- RESULT ----------
	rpm -qa | grep Maria

	echo $(rpm -qa | grep Maria | wc -l) / 4 are installed
# 216 서버 참조
# 서버설정시 /etc/my.cnf.d/server.cnf
	echo ------------ END -----------

	unset A

# mysql -p 접속후 커넥션수 10000, open_file_limit = 65500 or 65536  내가 설정한 값으로 변했는지 확인
# select @@max_connections;
# SHOW VARIABLES LIKE 'open%';
}
## END ##

function WRTC(){

	EPEL_INSPECTION

	echo wget rsync telnet chronyc are essential packages. installing...

	sleep 2

	dnf install wget rsync telnet chrony

	GW=$(grep GATEWAY /etc/sysconfig/network-scripts/ifcfg-eno1 | awk -F"=" '{print $2}')

	sed -i 's/2.pool.ntp.org iburst/'$GW'/' /etc/chrony.conf

	systemctl start chronyd
	systemctl enabled chronyd

	echo ---------- RESULT ----------
	rpm -qa wget rsync telnet chrony

	echo $(rpm -qa wget rsync telnet chrony | wc -l) / 4 are installed

	chronyc sources
	echo ------------ END -----------
}

function IMAGEMAGICK(){

	EPEL_INSPECTION
	
	echo Imagick module is necessary to create or modify image. installing...

	sleep 2

	SP=$(find / -name Serverset)

	dnf config-manager --set-enabled powertools
	dnf install ImageMagick-libs.x86_64 ImageMagick.x86_64 ImageMagick-devel.x86_64
	cd ~
	wget https://pecl.php.net/get/imagick-3.7.0.tgz
	tar -zxvf imagick-3.7.0.tgz
	cd imagick-3.7.0/
	phpize
	./configure
	make
	make install

	echo ---------- RESULT ----------
	rpm -qa | grep ImageMagick
	echo ------------ END -----------
}

## goaccess ##
function GOACCESS(){

	EPEL_INSPECTION	

	echo Start installing goaccess...

	sleep 2

	dnf install goaccess

	echo ---------- RESULT ----------
	rpm -qa goaccess
	
	echo Done
# 사용법 goaccess 사이트 확인.
	cat ./goaccess.conf > /etc/goaccess/goaccess.conf
	ls -l /etc/goaccess/goaccess.conf
	echo ------------ END -----------
}

##Installing git and nfs utilities##
function GIT_NFS(){

	EPEL_INSPECTION

	echo Installng git and nfs-utils...

	sleep 2

	dnf install git

	dnf install nfs-utils

	echo ---------- RESULT ----------
	rpm -qa | egrep 'git-|Git|perl-TermReadKey|nfs-utils'

	echo $(rpm -qa | egrep 'git-|Git|perl-TermReadKey|nfs-utils' | wc -l) / 4 are installed
	echo ------------ END -----------
	
	echo Is this process for new blogpay-web server?? [y\|n]
	
	read A

	case $A in
	y|Y|Yes|yes)
		cd /home/
		git clone http://10.100.100.129/UDID/BlogPay.git blogpay
		cd blogpay
		chown -R apache. web
		cd $(find / -name Serverset)
		echo -e blogpay is cloned\\nMake additional necessary img directories and proceed nfs works by your own if needed\\nRsync pear to /usr/share/, vendor and .env to /home/blogpay/web/ is also necessary.

		sleep 2

		sed -i 's/server_name/http_host/' /etc/nginx/fastcgi_params
		grep 'SERVER_NAME' /etc/nginx/fastcgi_params

		echo "Generating laravel logrotate config.."
		cat ./laravellogrotate > /etc/logrotate.d/laravel
		ls -l /etc/logrotate.d/laravel
		echo Done
	;;
	*)
		echo Done
	;;
	esac
	
	unset A
}

#dnf cacache

function GLANCES(){

	EPEL_INSPECTION

	echo Reforming dnf cache...

	sleep 2

	dnf makecache

#기존 glances 찾기

	if [ ! -z $(rpm -qa | grep glances) ]; then
#삭제		
		echo Erasing existing glances package...

		sleep 2		

		dnf erase glances-2.5.1-1.el7.noarch
	fi

#python 3.6 설치
#ius repository 설치 되어 있어야 함.

	echo Installing python3...
	dnf install python36

#glances bottle 설치

	echo Upgrading pip...

	sleep 1

	pip3.6 install --upgrade pip

	echo Installing glances bottle...

	sleep 1

	pip3.6 install glances bottle

	echo Installing influxdb

	sleep 1

	pip3.6 install influxdb

	echo Done

	echo Glances configuring...

	sleep 2
#glances 설정
#[influxdb] tag수정 : tags=host:218.232.75.219 => 현재서버의 아이피.
	mkdir /etc/glances

	sed 's/'tags=host:218.232.75.219'/'tags=host:$(cat /etc/sysconfig/network-scripts/$(ls /etc/sysconfig/network-scripts | grep ifcfg | sort | head -1) | grep IPADDR | awk -F"=" '{print $2}')'/' ./glances.conf >> /etc/glances/glances.conf

	echo glances.conf is generated
#glances.service 

	cat ./glances.service > /usr/lib/systemd/system/glances.service

#링크 생성
	ln -s /usr/lib/systemd/system/glances.service /etc/systemd/system/multi-user.target.wants/glances.service

	echo glances.service is generated

	echo Would you like to start/enable glances? [y\|n]

	read A
	
	case $A in
	y|Y)
# demon-reload
		systemctl daemon-reload

# glances start
		systemctl start glances.service
		systemctl enable glances.service
	;;
	*)
		echo -e You chose No or irrelevant option\\nNot starting glances
	esac

	unset A

	echo ---------- RESULT ----------
	systemctl status glances.service
	echo ------------ END -----------
}

function SELINUX_STATUS(){
	STATUS=$(sestatus | grep 'SELinux status' | awk '{print $3}')
	SELCONF=$(grep 'SELINUX=' /etc/selinux/config | grep -v '#' | awk -F"=" '{print $2}')
	if [[ "$STATUS" != "disabled" ]]
	then
		if [[ "$SELCONF" == "disabled" ]]
		then
			echo "SELinux is still on, make sure you reboot to apply"
		else
			sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config
			grep 'SELINUX=' /etc/selinux/config | grep -v '#'
			echo "Make sure you reboot the system to apply"
		fi
	else
		sestatus
	fi
}

MAKE_INSTALLED=$(rpm -qa | grep make)

if [ -z "$MAKE_INSTALLED" ]
then
	dnf install make
fi

SELINUX_STATUS

echo -e Welcome to Serverset/Setting.sh.\\nChoose one option you want to proceed.
echo options : 1 2 3 4 5 6 7 8 9 10 11 12 web DB
echo 1. sysctl.conf configuration
echo 2. limits.conf configuration
echo 3. EPEL Repository installation
echo 4. php7.2, ImageMagick installation
echo 5. composer installation
echo 6. memcached, redis installation
echo 7. MariaDB installation
echo 8. wget, rsync, telnet, chrony command installation
echo 9. imagick installation
echo 10. goaccess installation
echo 11. git, nfs-util installation
echo 12. glances installation and configuration
echo web. Running all web configuration needed for Web\(nginx\)
echo DB. Running all DB configuration needed for DB\(MariaDB\)
echo Input below

read OPTION

case $OPTION in
1)
	SYSCTL_CONF
;;
2)
	LIMITS_CONF
;;
3)
	EPEL_REPO
;;
4)
	NGINX_PHP72
;;
5)
	COMPOSER
;;
6)
	MEMCACHED_REDIS
;;
7)
	MARIADB
;;
8)
	WRTC
;;
9)
	IMAGEMAGICK
;;
10)
	GOACCESS
;;
11)
	GIT_NFS
;;
12)
	GLANCES
;;
web|WEB|Web)
	SYSCTL_CONF
	LIMITS_CONF
	EPEL_REPO
	NGINX_PHP72
	COMPOSER
	MEMCACHED_REDIS
	WRTC
	IMAGEMAGICK
	GOACCESS
	GIT_NFS
	GLANCES

	mkdir /etc/nginx/ssl
	cd /etc/nginx/ssl/
	openssl dhparam -out dhparam.pem 2048	

	echo Would you like to start/enable nginx? [y\|n]
	read A
	case $A in
	y|yes|YES|Yes)
		systemctl start nginx
		systemctl enable nginx
		systemctl status nginx
	;;
	*)
		echo -e You chose no or irrelevant option\\nnginx is not up
	esac

	unset A

	echo Would you like to start/enable php-fpm? [y\|n]
	read A
	case $A in
	y|yes|YES|Yes)
		systemctl start php-fpm
		systemctl enable php-fpm
		systemctl status php-fpm
	;;
	*)
		echo -e You chose no or irrelevant option\\nnginx is not up
	esac

	echo -e "Make sure you generate or rsync\\n1./etc/hosts\\n2./etc/php-fpm.d/www.conf\\n3./etc/nginx/nginx.conf\\n4./etc/php.ini\\nfrom other recent installed server\nAnd make sure /etc/php.ini has extension=mongodb.so, extension=imagick.so definition"

	unset A
;;
DB|db)
	SYSCTL_CONF
	LIMITS_CONF
	EPEL_REPO
	WRTC
	MARIADB
	GLANCES
	echo Agree to daemon-reload and start/enable mariadb? [y\|n]
	
	read A
	
	case $A in
	y|Y)
		systemctl daemon-reload
		systemctl start mariadb
		systemctl enable mariadb
		systemctl status mariadb

		echo Done
	;;
	*)
		echo -e You chose No or irrelevant option\nNothing changed
	;;
	esac
;;
*)
	echo -e You typed irrelevant option\\nprogram is canceled
;;
esac
