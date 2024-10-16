#!/bin/sh

NAME=$(echo $1 | awk -F"." '{print $1}')

if [ ! -r /vagrant/share/$NAME.key -o ! -r /vagrant/share/$NAME.pem ]
then
	echo -e "Make sure you generate integrated ssl authentication file and key file at /vagrant/share/ by your own. $NAME.key / $NAME.pem does not exist\\n$0 parameter usage : [domain]"
else
	ls -l /vagrant/share | egrep ''$NAME'.key|'$NAME'.pem'
	echo "They exists!"

	openssl rsa -noout -modulus -in /vagrant/share/$NAME.key >> keymodulus.txt
	openssl x509 -noout -modulus -in /vagrant/share/$NAME.pem >> pemmodulus.txt
		
	if [ -z "$(diff keymodulus.txt pemmodulus.txt)" ]
	then
		echo "Moduluses are same"
		if [ ! -d "/etc/nginx/ssl/userSSL/" ]; then
			mkdir -p /etc/nginx/ssl/userSSL/
		fi
		
		cp /vagrant/share/$NAME.key /etc/nginx/ssl/userSSL/
		chmod 644 /etc/nginx/ssl/userSSL/$NAME.key
		chown root. /etc/nginx/ssl/userSSL/$NAME.key
		cp /vagrant/share/$NAME.pem /etc/nginx/ssl/userSSL/
		chmod 644 /etc/nginx/ssl/userSSL/$NAME.pem
                chown root. /etc/nginx/ssl/userSSL/$NAME.pem
		
		if [ ! -f "/etc/nginx/user.d/sampleconf" ]; then
			mkdir -p /etc/nginx/user.d/
			cp -p /home/scorpiussoft/sampleconf /etc/nginx/user.d/sampleconf
		fi

		cp /etc/nginx/user.d/sampleconf /etc/nginx/user.d/$NAME.conf
		sed -i 's/sample/'$1'/g' /etc/nginx/user.d/$NAME.conf
		for i in sampem samkey
		do
        		sed -i 's/'$i'/'$NAME'/g' /etc/nginx/user.d/$NAME.conf
		done
	else
		echo "Moduluses are different"
		diff keymodulus.txt pemmodulus.txt
	fi
	
	rm -f keymodulus.txt pemmodulus.txt

	nginx -t
fi
	
