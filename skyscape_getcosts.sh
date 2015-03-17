#!/bin/bash
FOG_CREDENTIAL=test_credentials time vcloud-walk  organization > organization.json
for i in LIST YOUR ENVIRONMENTS HERE; do
cost=`ruby skyscape_costparse.rb  -m | grep -i " $i " | awk -F\: '{print $2}'`
zabbix_sender -k skyscape.price.$i -o $cost -z localhost -s "Zabbix server"
done
cost=`ruby skyscape_costparse.rb -m | grep TOTAL | awk -F\: '{print $2}'`
zabbix_sender -k skyscape.price.total -o $cost -z localhost -s "Zabbix server"
