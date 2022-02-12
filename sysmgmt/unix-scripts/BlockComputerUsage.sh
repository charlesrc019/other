#!/bin/sh

#
#   .SYNOPSIS
#   This script is meant to monitor a masOS computer's usage
#   and prevent users from doing disallowed things.
#
#   .AUTHOR
#   Charles Christensen
#
#   .NOTES
#   For best usage, add as a LaunchDaemon to run as root on
#   startup and block chflags, killall, su, and visudo in sudoers.
#

# Initialize.
echo "Starting BlockComputerUsage.sh on `date` as `whoami`..." > /Library/Logs/BlockComputerUsage.log
echo " " >> /Library/Logs/BlockComputerUsage.log
run_once=0
run_fivesecs=0

# Monitor tasks.
while [ 1 ]
do

    # Prevent night-time computer usage. (blocks 5pm - 9am & Sundays)
    dow=$(date +%A)
    hr=$(date +%H)
    if (( 10#$hr < 9 )) || (( 10#$hr >= 17 )) || [ $dow == "Sunday" ]
    then
        echo "> Shutting down." >> /Library/Logs/BlockComputerUsage.log
        shutdown -h now  >> /Library/Logs/BlockComputerUsage.log
    fi

    # Prevent extra users.
    dscl . list /Users | grep -v "^_" | while read -r line
    do
        if [ $line != "cchristensen" ] &&
           [ $line != "daemon"       ] &&
           [ $line != "nobody"       ] &&
           [ $line != "root"         ]
        then
            echo "> Deleting user '$line'." >> /Library/Logs/BlockComputerUsage.log
            dscl . -delete /Users/$line >> /Library/Logs/BlockComputerUsage.log
        fi
    done

    # Prevent extra user folders.
    ls /Users | while read -r line
    do
        if [ $line != "cchristensen" ] &&
           [ $line != "Shared"       ] &&
           [ $line != ".localized"   ]
        then
            echo "> Deleting user folder '$line'." >> /Library/Logs/BlockComputerUsage.log
            rm -rf /Users/$line >> /Library/Logs/BlockComputerUsage.log
        fi
    done

    # Prevent user from modifying this file, its startup, or hosts.
    [[ $0 = /* ]] && fullpath=$0 || fullpath=$PWD/${0#./}
    chown root:wheel $fullpath
    chflags schg $fullpath
    chflags uchg $fullpath
    chown root:wheel /Library/LaunchDaemons/com.charlesrc19.BlockComputerUsage.plist
    chflags schg /Library/LaunchDaemons/com.charlesrc19.BlockComputerUsage.plist
    chflags uchg /Library/LaunchDaemons/com.charlesrc19.BlockComputerUsage.plist
    chown root:wheel /private/etc/hosts
    chflags schg /private/etc/hosts
    chflags uchg /private/etc/hosts

    # Run five-second tasks.
    sec=$(date +%S)
    if (( 10#$run_fivesecs < 10#$sec ))
    then
        let run_fivesecs=$sec+5
        if (( 10#$run_fivesecs > 60 ))
        then
            let run_fivesecs=$run_fivesecs-60
        fi

        # Prevent extra user creation.
        security -q authorizationdb read  system.preferences.accounts > /tmp/system.preferences.accounts.plist
        defaults write /tmp/system.preferences.accounts.plist group wheel > /dev/null
        security -q authorizationdb write system.preferences.accounts < /tmp/system.preferences.accounts.plist

        # Prevent time modification.
        security -q authorizationdb read  system.preferences.datetime > /tmp/system.preferences.datetime.plist
        defaults write /tmp/system.preferences.datetime.plist group wheel > /dev/null
        security -q authorizationdb write system.preferences.datetime < /tmp/system.preferences.datetime.plist

        # Prevent screen recording modification.
        security -q authorizationdb read  system.preferences.security > /tmp/system.preferences.security.plist
        defaults write /tmp/system.preferences.security.plist group wheel > /dev/null
        security -q authorizationdb write system.preferences.security < /tmp/system.preferences.security.plist

    fi

    # Run one-time tasks.
    if [ $run_once == 0 ]
    then
        run_once=1

        # Update hosts.
        if [ $dow = "Monday" ]
        then
            echo "> Updating hosts file..." >> /Library/Logs/BlockComputerUsage.log
            sleep 30 > /dev/null
            chflags noschg /private/etc/hosts
            chflags nouchg /private/etc/hosts
            rm /private/etc/hosts
            echo "> Downloading updated hosts file..." >> /Library/Logs/BlockComputerUsage.log
            curl -m 30 -s --retry 3 --retry-delay 1 --connect-timeout 3 https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts -o /private/etc/hosts
            echo "> New host file downloaded." >> /Library/Logs/BlockComputerUsage.log
            cat /Users/cchristensen/Documents/hosts_custom.txt >> /private/etc/hosts
            killall -HUP mDNSResponder
            echo "> Complete!" >> /Library/Logs/BlockComputerUsage.log
            echo " " >> /Library/Logs/BlockComputerUsage.log
        fi

    fi

    sleep 0.1 > /dev/null

done
