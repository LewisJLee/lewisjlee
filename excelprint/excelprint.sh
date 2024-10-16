#!/bin/sh
echo "Input DB Server ip"
read DB
echo "Input SiteID"
read ID
echo "1.Product\n2.Member\n3.Board"
read OPTION
case $OPTION in
1)
	EXESQL="./run/product.sh"
;;
2)
	EXESQL="./run/member.sh"
;;
*)
	echo "You chose irrelevant option or No"
;;
esac	

if [ -z "$DB" -o -z "$ID" ]; then
	echo "$0 usage : $0 [ DB Server ip ] [ SiteID ]"
elif [ -z "$OPTION" ]; then
	break;
elif [ ! -r ${EXESQL} ]; then
	echo "${EXESQL} does not exist"
else
	sed 's/SITEID/'$ID'/g' ${EXESQL} > runtemp.sh

	ssh simple2x@$DB "bash -s" < runtemp.sh > /vagrant/$ID.csv

	if [ ! -r /vagrant/$ID.csv ]; then
		echo "Failed to generate CSV."
	else
		ls -l /vagrant/$ID.csv
		echo "Do you agree to print result?"
		read A
		case $A in
		yes|YES|Yes|y)
			cat /vagrant/$ID.csv | more
		;;
		*)
			echo "You answered No."
		;;
		esac
	fi
	
	rm -f ./runtemp.sh
fi
