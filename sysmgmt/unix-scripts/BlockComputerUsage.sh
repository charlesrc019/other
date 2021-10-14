#!/bin/sh

#
#   .SYNOPSIS
#   This script is meant to monitor a masOS computer's usage
#   and prevent users from doing disallowed things.
#
#   .AUTHOR
#   Charles Christensen
#

# Initialize.
echo "Starting BlockComputerUsage.sh on `date`...\n" > /Library/Logs/BlockComputerUsage.log
ran_once=0

# Monitor tasks.
while [ 1 ]
do

    # Prevent night-time computer usage.
    hr=$(date +%H)
    dow=$(date +%A)
    if (( 10#$hr < 7 )) || (( 10#$hr >= 17 )) || [ $dow == "Sunday" ]
    then
        echo "> Shutting down..." >> /Library/Logs/BlockComputerUsage.log
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
    chflags schg $fullpath
    chflags uchg $fullpath
    chflags schg /Library/LaunchDaemons/com.charlesrc19.BlockComputerUsage.plist
    chflags uchg /Library/LaunchDaemons/com.charlesrc19.BlockComputerUsage.plist
    chflags schg /private/etc/hosts
    chflags uchg /private/etc/hosts
    
    # Prevent using Terminal.
    pid=$(pgrep -x "Terminal")
    if [ -z "$pid" ]
    then
        echo "" >> /dev/null
    else
        echo "> Terminal blocked." >> /Library/Logs/BlockComputerUs$
        killall Terminal >> /Library/Logs/BlockComputerUsage.log
        kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
    fi

    sleep 0.1 > /dev/null

    # Run one-time tasks.
    if [ $ran_once == 0 ]
    then
        ran_once=1

        # Prevent extra user creation.
        echo "> Adding flags to prevent user account creation..." >> /Library/Logs/BlockComputerUsage.log
        security -q authorizationdb read  system.preferences.accounts > /tmp/system.preferences.accounts.plist
        defaults write /tmp/system.preferences.accounts.plist group wheel > /dev/null
        security -q authorizationdb write system.preferences.accounts < /tmp/system.preferences.accounts.plist
        echo "> Complete!\n" >> /Library/Logs/BlockComputerUsage.log

        # Update hosts.
        if [ $dow = "Monday" ]
        then
            echo "> Updating hosts file..." >> /Library/Logs/BlockComputerUsage.log
            sleep 30 > /dev/null
            chflags noschg /private/etc/hosts
            chflags nouchg /private/etc/hosts
            rm /private/etc/hosts
            echo "> Downloading updated hosts file..." >> /Library/Logs/BlockComputerUsage.log
            curl -m 2 -s --retry 1 --retry-delay 1 --connect-timeout 2 https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts -o /private/etc/hosts
            echo "> New host file downloaded." >> /Library/Logs/BlockComputerUsage.log
            cat /private/etc/hosts_custom.txt >> /private/etc/hosts
            sudo sudo killall -HUP mDNSResponder
            chflags schg /private/etc/hosts
            chflags uchg /private/etc/hosts
            echo "> Complete!\n" >> /Library/Logs/BlockComputerUsage.log
        fi
    fi

done
