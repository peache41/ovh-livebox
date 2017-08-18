#! /bin/bash
# Mainly inspired by DynHost script given by OVH
# New version by zwindler (zwindler.fr/wordpress)
# Newer version stores the return code in the logfile (smuller@s-muller.fr)
#
# Initial version was doing nasty grep/cut on local ppp0 interface
#
# This coulnd't work in a NATed environnement like on ISP boxes
# on private networks.
#
# Also got rid of ipcheck.py thanks to mafiaman42
#
# This script uses curl to get the public IP, and then uses wget
# to update DynHost entry in OVH DNS
#
# Logfile: dynhost.log
#
# CHANGE: "HOST", "LOGIN" and "PASSWORD" to reflect YOUR account variables

HOST="TO CHANGE"
LOGIN="TO CHANGE"
PASSWORD="TO CHANGE"
LOG_PATH="TO CHANGE"
LIVEBOX="TO CHANGE"

echo ---------------------------------- >> $LOG_PATH/dynhost.log
echo `date` >> $LOG_PATH/dynhost.log
echo 'DynHost' >> $LOG_PATH/dynhost.log

TMPFILE=`tempfile`

IP=`curl -s -X POST -H "Content-Type: application/x-sah-ws-1-call+json" -d '{"service":"NMC","method":"getWANStatus","parameters":{}}' http://$LIVEBOX/ws | sed -e 's/.*"IPAddress":"\(.*\)","Remo.*/\1/g'`
IPv6=`curl -s -X POST -H "Content-Type: application/x-sah-ws-1-call+json" -d '{"service":"NMC","method":"getWANStatus","parameters":{}}' http://$LIVEBOX/ws | sed -e 's/.*"IPv6Address":"\(.*\)","IPv6D.*/\1/g'`
OLDIP=`dig +short @$LIVEBOX $HOST`

if [ $IP ]; then
  if [ $OLDIP != $IP ]; then
    echo -n 'Old IP: ' >> $LOG_PATH/dynhost.log
    echo $OLDIP >> $LOG_PATH/dynhost.log
    echo -n 'New IP: ' >> $LOG_PATH/dynhost.log
    echo $IP >> $LOG_PATH/dynhost.log
    echo 'Try to update!' >> $LOG_PATH/dynhost.log
    wget -q -O $TMPFILE "http://www.ovh.com/nic/update?system=dyndns&hostname=$HOST&myip=$IP" --user="$LOGIN" --password="$PASSWORD" >> $LOG_PATH/dynhost.log
    RESULT=`cat $TMPFILE`
    echo "Result: $RESULT" >> $LOG_PATH/dynhost.log
    if [[ $RESULT =~ ^(good|nochg).* ]]; then
      echo ---------------------------------- >> $LOG_PATH/dynhost-changes.log
      echo `date` >> $LOG_PATH/dynhost-changes.log
      echo "New IP : $IP" >> $LOG_PATH/dynhost-changes.log
    fi
    rm $TMPFILE
  else
    echo "IP $HOST $OLDIP is identical to WAN $IP! No update required." >> $LOG_PATH/dynhost.log
  fi
else
  echo 'WAN IP not found. Exiting!' >> $LOG_PATH/dynhost.log
fi

# Some implementations of 'wc' use tabulation as separator others use space.
NB_LINES=`wc -l $LOG_PATH/dynhost.log | cut -d" " -f1 | cut -f1`
if [ "$NB_LINES" -gt "200" ]; then
  tail -n100 $LOG_PATH/dynhost.log >> $TMPFILE
  mv $TMPFILE $LOG_PATH/dynhost.log
fi
