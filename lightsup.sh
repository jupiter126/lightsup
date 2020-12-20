#!/bin/bash
#############
# Simple script to update lighthouse prebuilt binaries.
#############
# MIT LICENCE
# Copyright 2020 - 2021 jupiter126@gmail.com
#####
# V0.3
##### Please set these one accordingly
workdir="/home/jupiter/lightsup" && cd "$workdir" || exit
# To remove color codes, comment the following line (cleanlogs).
def=$(tput sgr0);bol=$(tput bold);red=$(tput setaf 1;tput bold);gre=$(tput setaf 2;tput bold);yel=$(tput setaf 3;tput bold);blu=$(tput setaf 4;tput bold);mag=$(tput setaf 5;tput bold);cya=$(tput setaf 6;tput bold)
#####
vverbal="1"
bckfail="0"
latestver=$(/usr/bin/curl -s https://github.com/sigp/lighthouse/releases/latest|cut -f2 -d'"'|rev|cut -f1 -d'/'|rev)

function f_timestamp {
	timestamp="$(date +%Y%m%d%H%M)"
}

function f_say { # manages script output: 0 = none; 1 = print ; 2 = log; 3 = print and log
	f_timestamp
	case $vverbal in
		0) return 0;;
		1) echo "$timestamp: $message";;
		2) touch "$workdir/lightsuplog.txt" && echo "$timestamp: $message" >> "$workdir/lightsuplog.txt";;
		3) touch "$workdir/lightsuplog.txt" && echo "$timestamp: $message" | tee -a lightsuplog.txt;;
		*) echo "$timestamp: This is not supposed to happen" && SCRIPT_VARS="$(grep -vFe "$VARS" <<<"$(set -o posix ; set)" | grep -v ^VARS=)"; echo "$red$SCRIPT_VARS$def"; exit ;;
	esac
}

if [[ -f "$workdir/config_prebuilt.txt" ]]; then
	# shellcheck source=./config_prebuilt.txt
	source "$workdir/config_prebuilt.txt"
else
	message="$bol Please copy$yel config_prebuilt.txt.sample$red as$yel config_prebuilt.txt$red and edit it to fit your needs$def" && f_say ; exit
fi

function f_cleanlog {
	if [[ -f "$workdir/lightsuplog.txt" ]]; then
		if [[ "$(wc -l "$workdir/lightsuplog.txt")" -ge "1000" ]]; then # keep between 750 and 1000 lines in log
			tail -n 750 "$workdir/lightsuplog.txt" > "$workdir/templog.txt"
			sleep 1
			mv "$workdir/templog.txt" "$workdir/lightsuplog.txt"
		fi
	fi
}

function f_security_check {
	if [[ -f /usr/local/bin/lighthouse ]]; then
		if [[ -f "$workdir/lighthouse.checksum.txt" ]]; then
			if [[ "x$(/usr/bin/sha512sum /usr/local/bin/lighthouse|cut -f1 -d' ')" != "x$(cat $workdir/lighthouse.checksum.txt)" ]]; then
				message="$red !!! WARNING: Checksums don't match: either you did not update as should or you might have been hacked !!! $def" && f_say
			else
				message="$gre Security Checksum test passed $def" && f_say
			fi
		else
			message="$red !!! WARNING: No checksum file, either you didn't secure lighthouse with this script, or you might have been hacked !!! $def" && f_say
		fi
		if [[ "$(/usr/bin/lsattr /usr/local/bin/lighthouse|cut -f1 -d' '|grep i)" = "" ]]; then
			message="$red !!! WARNING: File attributes not correct, either you didn't secure lighthouse with this script, or you might have been hacked !!! $def" && f_say
		fi
	else
		message="$cya !!! WARNING: Lighthouse not detected !!! $def" && f_say
	fi
	if [[ -d  /var/lib/lighthouse/beacon/ ]]; then
		if [[ "x$(stat -c "%a %U %G" /var/lib/lighthouse/beacon/)" != "x700 $bnuser $bnuser" ]]; then
			message="$red /var/lib/lighthouse/beacon/ has insecure ownership/rights $def" && f_say
		fi
	fi
	if [[ -d  /var/lib/lighthouse/validators/ ]]; then
		if [[ "x$(stat -c "%a %U %G" /var/lib/lighthouse/validators/)" != "x700 $vtuser $vtuser" ]]; then
			message="$red !!! /var/lib/lighthouse/validators/ has insecure ownership/rights !!! $def" && f_say
		fi
	fi
}

function f_schedulecheck {
	# this part will be automated when I find this info on an API
	read -r -p 'Check on https://beaconcha.in/blocks : is it a good time to update this validator (not scheduled)?' yn
	case $yn in
		[Yy]* ) return 0;;
		[Nn]* ) return 1;;
		* ) echo "Please answer yes or no.";;
	esac
}

function f_versioncheck { #sets $currentver and $latestver
	if [[ -f /usr/local/bin/lighthouse ]]; then
		currentver="$(/usr/local/bin/lighthouse --version|head -n1|cut -f 2 -d' '|cut -f1 -d'-')"
	else
		currentver="0.0.0"
	fi
}

function f_prepare_update {
#	apt update && apt -y upgrade
	f_backup0 || message="$red Backup Failed $def" ; return 3
	if /usr/bin/wget -q -P "$workdir" "https://github.com/sigp/lighthouse/releases/download/$latestver/lighthouse-$latestver-$localversion.tar.gz"; then
		if /usr/bin/wget -q -P "$workdir" "https://github.com/sigp/lighthouse/releases/download/$latestver/lighthouse-$latestver-$localversion.tar.gz.asc"; then
			gpg --verify "$workdir/lighthouse-$latestver-$localversion.tar.gz.asc" "$workdir/lighthouse-$latestver-$localversion.tar.gz" 2>"$workdir/pgptest"
			if [[ "$(grep 15E66D941F697E28F49381F426416DC3F30674B0 $workdir/pgptest)" = "" ]]; then
				message="$yel !!!$red pgp key does not match $yel!!!$def" && f_say
				rm "$workdir/pgptest"
				return 2
			fi
			rm "$workdir/pgptest"
			/usr/bin/tar -xzf "lighthouse-$latestver-$localversion.tar.gz" && rm "lighthouse-$latestver-$localversion.tar.gz" "lighthouse-$latestver-$localversion.tar.gz.asc"
			message="$gre $latestver is ready to be installed $def" && return 0
		fi
	else
		message="new version detected but not available as prebuilt yet." && f_say
		return 1
	fi
}

function f_apply_update {
	f_losenrights
	testversion="$workdir/lighthouse"
	if [[ "x$($testversion --version|head -n1|cut -f 2 -d' '|cut -f1 -d'-')" = "x$latestver" ]]; then
		mv "$testversion" /usr/local/bin/
	else
		message="$red downloaded version is somehow not the latest $def" && f_say
	fi
}

function f_stop_services { #stop vt befor bn
	for thisservice in $vtsysdname $bnsysdname; do
		/usr/bin/systemctl stop "$thisservice"
		until [[ "x$(systemctl is-active "$thisservice")" = "xinactive" ]]; do
			sleep 1; message="Waiting for $thisservice to stop. . ." && f_say
		done
	done
	message="$gre $vtsysdname and $bnsysdname have been$yel stopped! $def" && f_say
}

function f_start_services { #start bn before vt
	for thisservice in $bnsysdname $vtsysdname; do
		/usr/bin/systemctl start "$thisservice"
		until [[ "x$(systemctl is-active "$thisservice")" = "xactive" ]]; do
			sleep 1; message="Waiting for $thisservice to start. . ." && f_say
		done
	done
	message="$gre $bnsysdname and $vtsysdname have been$yel  started $def" && f_say
}

function f_backup0 { # before update
	cp /etc/systemd/system/lighthousevalidator.service "$workdir/backup/" || bckfail="1"
	cp /etc/systemd/system/lighthousebeacon.service "$workdir/backup/" || bckfail="1"
	cp /usr/local/bin/lighthouse "$workdir/backup/" || bckfail="1"
	f_checkbackup; return "$?"
}

function f_backup1 { # when services down
	tar -czf "$workdir/backup/validator.tar.gz" /var/lib/lighthouse/validators/ || bckfail="1"
	f_checkbackup; return "$?"
}

function f_backup2 { # after update
	f_timestamp
	tar -cvzf "$workdir/backup-timestamp.tar.gz" "$workdir/backup" || bckfail="1"
	f_checkbackup; return "$?"
}

function f_checkbackup {
	if [[ $bckfail = "1" ]]; then
		message="$red Backup failed" && f_say ; bckfail="0"; return 1
	else
		return 0
	fi
}

function f_fallback { # puts lighthouse bin from backup back in place
	f_stop_services
	f_losenrights
	cp "$workdir/backup/lighthouse" /usr/local/bin/lighthouse
	f_setsecrights
	f_start_services
}

function f_only_backup {
	f_backup0 || return 1
	f_stop_services
	f_backup1
	f_start_services
	f_backup2
}

function f_losenrights {
	if [[ -f /usr/local/bin/lighthouse ]]; then
		/usr/bin/chattr -i /usr/local/bin/lighthouse
	fi
}

function f_setsecrights {
	/usr/bin/chown root:root /usr/local/bin/lighthouse
	/usr/bin/chmod 755 /usr/local/bin/lighthouse
	/usr/bin/chattr +i /usr/local/bin/lighthouse
	/usr/bin/sha512sum /usr/local/bin/lighthouse|cut -f1 -d' ' > "$workdir/lighthouse.checksum.txt"
	/usr/bin/chown $bnuser:$bnuser /var/lib/lighthouse/beacon
	/usr/bin/chmod 700 /var/lib/lighthouse/beacon
	/usr/bin/chown $vtuser:$vtuser /var/lib/lighthouse/validators
	/usr/bin/chmod 700 /var/lib/lighthouse/validators
	/usr/bin/chown root:$vtuser "/etc/systemd/system/$vtsysdname.service"
	/usr/bin/chmod 640 "/etc/systemd/system/$vtsysdname.service"
	/usr/bin/chown root:$bnuser "/etc/systemd/system/$bnsysdname.service"
	/usr/bin/chmod 640 "/etc/systemd/system/$bnsysdname.service"
}

function f_autoprebuilt {
	f_versioncheck
	if [[ "x$currentver" != "x$latestver" ]]; then
		message="$red Requires update ( $currentver != $latestver ) $def" && f_say
		f_prepare_update
		[ "x$?" != "x0" ] && exit # exit if prepare update fails
		f_schedulecheck
		[ "x$?" != "x0" ] && exit # exit if it is not a good time
		f_stop_services
		f_backup1
		f_apply_update
		f_setsecrights
		f_start_services
		f_backup2
		f_cleanlog
	else
		message="$gre up to date ( $currentver = $latestver ) $def" && f_say
	fi
}

function m_main { # Main Menu (displayed if called without args)
	echo "$bol Carefull: backup and fallback operations imply restarting services $def"
	while true; do
		PS3='Choose a number: '
		select choix in "Prepare update" "Stop services" "Apply update" "Set secure rights" "Start services" "Only Backup" "Do everything" "Fallback" "Quit"
		do
			break
		done
		case $choix in
			"Prepare update")	f_prepare_update ;;
			"Stop services")	f_stop_services ;;
			"Apply update")		f_apply_update ;;
			"Set secure rights")	f_setsecrights ;;
			"Start services")	f_start_services ;;
			"Only Backup")		f_only_backup ;;
			"Do everything")	f_autoprebuilt ;;
			"Fallback")		f_fallback;;
			Quit)		echo "$gre bye ;) $def";exit ;;
			*)		echo "$mag Same player shoot again!$def" ;;
		esac
	done
}

function f_help {
	echo "$yel Starts menu if launched without parameters, else does autobuild$yel"
	echo "$blu Optionnal parameters are$yel
	- $red 0$yel: Shutup + nolog $def (not advised)
	- $red 1$yel: Speak  + nolog $def
	- $red 2$yel: Shutup + log $def (good for cron)
	- $red 3$yel: Speak  + log $def"
}

#Main entry point: Displays menu if no arguments passed, displays help if wrong argument passed
f_security_check
if [[ "x$1" = "x" ]]; then
	m_main
elif [[ "x$2" != "x" ]]; then f_help;
else
	vverbal="$1"
	if [[ "$vverbal" -ge "0" ]] && [[ "$vverbal" -le "3" ]]; then
		f_autoprebuilt
	else
		f_help
	fi
fi
