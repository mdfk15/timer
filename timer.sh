#!/usr/bin/env bash
#  
#  by mdfk <mdfk@Elite>
#
#  To learn more about my projets
#  go to https://github.com/mdfk15/

# DEFAULTS
time_arguments=$1
path=$HOME/.local/share/timer
current_log=$path/current.log
history_log=$path/stats.log

[ ! -e $path ] && mkdir $path
[ ! -e $current_log ] && touch $current_log
if [ "$(date -r $current_log '+%d%m%y')" -lt "$(date '+%d%m%y')" ];then
	cat "$current_log" >> $history_log
	> $current_log
fi
[ ! -s "$current_log" ] && date '+%d.%m:0:0' > $current_log

hours=00
minutes=00
seconds=00

usage(){
	echo -e "Usage: timer [options]..
Options:
	-h [ --help ]	print this help menu
	1[s/S]		set time in 1 seconds
	2[m/M]		set time in 2 minutes
	3[h/H]		set time in 3 hours
	4h4m		set timestamps in 4 hours and 4minutes
	5:5:5		set timestamps (format: hh:mm:ss)
	-p <t> <p> <r>	set pomodore time intervals in minutes (format <t[ime]> <p[ause]> <r[epetitions]>)

#  Timer create by mdfk
#  To learn more about my projets go to https://github.com/mdfk15/"
	exit
}

msg_generator(){
	echo "Started at $(date +'%I:%M:%S %P')"
	time_set=$(date -d "@$seconds" -u +%H:%M:%S)
	msg=$(echo $time_set | awk -F: 'BEGIN {ORS=" "}; $1>=01 {print $1,"hours"} $2>=01 {print $2,"minutes"} $3>=01 {print $3,"seconds"}')
	echo "Time set: $msg"
}

time_to_seconds() {
	seconds=$(echo $1 | awk -F'[hHmMsS:]' '{ print ($1 * 3600) + ($2 * 60) + $3 }')
}

notify() {
	if [ "$timestamps" == "300" ] || [ "$timestamps" == 60 ] || [ "$timestamps" -lt 10 ] ;then
		time_to_notify=$(echo $time_left | awk -F: '$2==00 && $3<=10 && $3>=1 {print $3,"seconds to left"} $2==00 && $3==00 {print "Its time to do it!"} $2==01 || $2==05 {print $2,"minutes to left"}')
		systemctl --user is-active --quiet dunst && notify-send -i timer -a "Timer" "$time_to_notify" -r 34020
	fi
}

time_segmentation() {
	hours=$(echo "$time_arguments" | grep -oP '\d+([hH])' | sed -E 's/h|H//')
	minutes=$(echo "$time_arguments" | grep -oP '\d+([mM])' | sed -E 's/m|M//')
	seconds=$(echo "$time_arguments" | grep -oP '\d+([sS])' | sed -E 's/s|S//')
	time_to_seconds "$hours:$minutes:$seconds"
}

time_counter() {
	# QUEST NOTIFICATION TO START
	ready_msg=$(echo -e "Are you ready?\nClick to start")
	user_ready="$(notify-send -A ready=userready -i timer -a 'Timer' "$ready_msg" -t 60000 -r 34020 >/dev/null 2>&1)"

	for i in $(seq $seconds);do
		timestamps=$(($seconds-$i))
		time_left=$(date -d "@$timestamps" -u +%H:%M:%S)
		echo -ne "\rTime left: $time_left $intervals_msg"
		notify
		sleep 1
	done
}

log_usage() {
	case "$time_status" in
		'Work')
			((stats_work+=$seconds));;
		'Break')
			((stats_break+=$seconds));;
	esac
	echo "$stats_day:$stats_work:$stats_break" > $current_log
}

pomodoro() {
	echo "Started at $(date +'%I:%M:%S %P')"
	stats_day=$(cat $current_log | awk -F: '{print $1}')
	stats_work=$(cat $current_log | awk -F: '{print $2}')
	stats_break=$(cat $current_log | awk -F: '{print $3}')

	# Define pomodoro, breaks and laps
	if [[ -n "$@" ]];then
		[ "$1" -gt "$2" ] && work_time="$1" break_time="$2" || work_time="$2" break_time="$1"
		time_laps="$3"
	else
		work_time=25
		break_time=5
		time_laps="2"
	fi

	# Start pomodoro laps count
	for i in $(seq $time_laps);do
		((interval+=1))
		intervals_started=''

		# Work and Breaks count
		for t in $work_time $break_time;do
			# Print if work or break time in bold
			if [ "$time_status" == "Break" ] || [ -z "$time_status" ];then
				time_status='Work'
				intervals_progress="\033[1m$work_time\033[m $break_time"
			else
				time_status='Break'
				intervals_progress="$work_time \033[1m$break_time\033[m"
			fi

			intervals_msg="- $time_status $intervals_progress ($interval/$time_laps)"

			# Start counter process
			seconds=''
			minutes=$t
			time_to_seconds "$hours:$minutes:$seconds"
			time_counter
			log_usage
		done
	done
}

timer() {
	# Check type of time segmentation
	if [[ "$time_arguments" =~ [hHmMsS] ]];then
		time_segmentation
	elif [[ "$time_arguments" =~ ':' ]];then 
		time_to_seconds "$time_arguments"
	else
		echo Error, pleace see the help menu for more information and try again. Thanks!
		exit
	fi
	msg_generator
	time_counter
}

if [[ "$time_arguments" =~ '-h' ]];then
	usage
elif [[ "$time_arguments" == '-p' ]];then
	pomodoro "${@:2}"
else
	timer
fi
	
echo -e "\nFinished at $(date +'%I:%M:%S %P'), thanks for use it"
