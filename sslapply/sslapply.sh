#!/bin/sh

NAME=$(echo $1 | awk -F"." '{print $1}')

if [ ! -r "/etc/nginx/ssl/dhparam.pem" ]
then
	if [ ! -d "/etc/nginx/ssl/" ]
	then
		mkdir /etc/nginx/ssl/
	fi
	echo -e "You have to generate ssl/dhparam.pem.\\nYou could do rsync from other web server."
fi
if [ ! -r "/etc/nginx/ssl/userSSL/$NAME.key" -o ! -r "/etc/nginx/ssl/userSSL/$NAME.pem" ]
then
	if [ ! -d "/etc/nginx/ssl/userSSL/" ]
	then
		mkdir /etc/nginx/ssl/userSSL/
	fi
	echo -e "Key file or pem file does not exist.\\nUsage : ./$0 [domain]"
fi
if [ ! -d /etc/nginx/user.d/ ]
then
	echo -e "user.d/ does not exist\\ncopying directory..."
	cp -rp user.d /etc/nginx/
	
else
	cp user.d/sampleconf /etc/nginx/user.d/
	cp user.d/samplenosslconf /etc/nginx/user.d/
fi
	
for i in sampleconf samplenosslconf
do
	sed -i 's/sample/'$1'/g' /etc/nginx/user.d/$i
	case $i in
	sampleconf)
		sed -i 's/sampem/'$NAME'.pem/g' /etc/nginx/user.d/$i
		sed -i 's/samkey/'$NAME'.key/g' /etc/nginx/user.d/$i
		mv /etc/nginx/user.d/$i /etc/nginx/user.d/$NAME.conf
	;;
	samplenosslconf)
		mv /etc/nginx/user.d/$i /etc/nginx/user.d/$NAME\_nossl.conf
	;;
	esac
done

nginx -t
