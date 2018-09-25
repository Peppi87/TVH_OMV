#!/bin/sh

#TVHeadend Username/Password
tvh_login="YourTVHeadendUser"
tvh_password="YourTVHeadendPasswort"
#TVHeadend Server IP/Port
tvh_ip_port="127.0.0.1:9981"
#Time to boot before DVR in sec
boot_pre_dvr="1200"
#No sleep time before next DVR in sec
no_sleep_pre_boot="7200"
#No sleep file for OMV AutoShutdown Plugin Erweiterte Optionen = PLUGINCHECK="true"
no_sleep_file="/var/run/tvh_subscriptions"
#OMV UID to create new Jobs
omv_new_job_uidv4="fa4b1c66-ef79-11e5-87a0-0002b3a176b4"
#Load OMV WakeUp Jobs
omv_wake_jobs=$(omv-confdbadm read conf.system.wakealarm.job | jq -r '.[]|.comment')

time_now=$(date +'%s')
no_sleep=0

check_dvr_entries() {
	dvr_entries_total=$(curl -s --user $tvh_login:$tvh_password http://$tvh_ip_port/api/dvr/entry/grid_upcoming |  awk -F 'total":' '{print $2}' | awk -F '}' '{print $1}')
	if [ $dvr_entries_total -ge 1 ]
		then
			#logger -t $(basename $0) "$dvr_entries_total geplante Aufnahmen vorhanden"
			echo "$dvr_entries_total geplante Aufnahmen vorhanden"
			i=1
			while [ $i -le $dvr_entries_total ]
				do
					e=$((i+1))
					dvr_startTime=$(curl -s --user $tvh_login:$tvh_password http://$tvh_ip_port/api/dvr/entry/grid_upcoming |  awk -F 'start_real":' '{print $'$e'}' |  awk -F ',' '{print $1}')
					bootTime=$(($dvr_startTime-$boot_pre_dvr))
					uuid=$(curl -s --user $tvh_login:$tvh_password http://$tvh_ip_port/api/dvr/entry/grid_upcoming |  awk -F 'start_real":' '{print $'$i'}' |  awk -F 'uuid":"' '{print $2}' | awk -F '",' '{print $1}')
					disp_name=$(curl -s --user $tvh_login:$tvh_password http://$tvh_ip_port/api/dvr/entry/grid_upcoming |  awk -F 'start_real":' '{print $'$e'}' | awk -F 'disp_title":"' '{print $2}' | awk -F '",' '{print $1}')
					bootMinute=$(date -d @$bootTime +'%M')
					bootHour=$(date -d @$bootTime +'%H')
					bootDay=$(date -d @$bootTime +'%-d')
					bootMonth=$(date -d @$bootTime +'%-m')
					
					if [ $(($bootTime - $time_now)) -le $no_sleep_pre_boot ] 
						then 
							no_sleep=1
						fi

					if echo $omv_wake_jobs | grep -q $uuid; then
						echo "WakeUp bereits geplant fuer $disp_name"
					else
						omv-rpc -u admin "Wakealarm" "setJob" "{\"uuid\":\"$omv_new_job_uidv4\",\"enable\":true,\"minute\":\""$bootMinute"\",\"everynminute\":false,\"hour\":\""$bootHour"\",\"everynhour\":false,\"dayofmonth\":\""$bootDay"\",\"everyndayofmonth\":false,\"month\":\""$bootMonth"\",\"dayofweek\":\"*\",\"comment\":\"$disp_name || $uuid\"}" >/dev/null
						echo "WakeUp wurde geplant fuer $disp_name"
						logger -t $(basename $0) "WakeUp wurde geplant fuer $disp_name"
					fi
					omv-rpc -u admin "Config" "applyChanges" '{"modules":["wakealarm"],"force":true}' >/dev/null
					#logger -t $(basename $0) "WakeUp Settings gespeichert"
					i=$((i+1))
			done
		else
		#logger -t $(basename $0) "Keine geplanten Aufnahmen vorhanden"
		echo "Keine geplanten Aufnahmen vorhanden"
	fi
}

check_subscriptions() {
	total_subscriptions=$(curl -s --user $tvh_login:$tvh_password http://$tvh_ip_port/api/status/subscriptions |  awk -F 'totalCount":' '{print $2}' | awk -F '}' '{print $1}')
	if [ $total_subscriptions -ge 1 ]
		then
			no_sleep=1
			#logger -t $(basename $0) "$total_subscriptions Subscription vorhanden"
			echo "$total_subscriptions Subscription vorhanden"
		else
			echo "Keine Subscriptions vorhanden"
			#logger -t $(basename $0) "Keine Subscription vorhanden"
			[ -e $no_sleep_file ] && rm $no_sleep_file
	fi

}


check_dvr_entries
check_subscriptions


if [ $no_sleep -eq 1 ]
	then
		echo 1 > $no_sleep_file
		echo "Bereitschaftsmodus wird verhindert"
	else
		[ -e $no_sleep_file ] && rm $no_sleep_file
		echo "Bereitschaftsmodus wird nicht verhindert"
fi
