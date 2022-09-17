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
main_user="cchristensen"
echo "Starting BlockComputerUsage.sh on `date` as `whoami`..." > /Library/Logs/BlockComputerUsage.log
echo " " >> /Library/Logs/BlockComputerUsage.log
run_once=0

# Monitor tasks.
while [ 1 ]
do

    # Prevent user from modifying this file, its startup, or hosts.
    [[ $0 = /* ]] && fullpath=$0 || fullpath=$PWD/${0#./}
    chflags schg $fullpath
    chflags uchg $fullpath
    chflags schg /Library/LaunchDaemons/com.user.BlockComputerUsage.plist
    chflags uchg /Library/LaunchDaemons/com.user.BlockComputerUsage.plist

    # Prevent night-time computer usage. (blocks 5pm - 9am & Sundays)
    dow=$(date +%A)
    hr=$(date +%H)
    if (( 10#$hr < 9 )) || (( 10#$hr >= 17 )) || [ $dow == "Sunday" ]
    then
        echo "> Shutting down." >> /Library/Logs/BlockComputerUsage.log
        shutdown -h now  >> /Library/Logs/BlockComputerUsage.log
    fi

    # Run one-time tasks.
    if [ $run_once == 0 ]
    then
        run_once=1

        echo "> Locking system modifications..." >> /Library/Logs/BlockComputerUsage.log

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

        echo "> Complete!" >> /Library/Logs/BlockComputerUsage.log
        echo " " >> /Library/Logs/BlockComputerUsage.log

        # Update hosts.
        chflags schg /etc/hosts
        chflags uchg /etc/hosts
        if [ $dow == "Monday" ]
        then
            echo "> Updating hosts file..." >> /Library/Logs/BlockComputerUsage.log
            chflags noschg /etc/hosts
            chflags nouchg /etc/hosts
            rm /etc/hosts
            cp /Users/cchristensen/Documents/hosts.txt /etc/hosts
            chown root:wheel /etc/hosts
            chmod 644 /etc/hosts
            killall -HUP mDNSResponder
            echo "> Complete!" >> /Library/Logs/BlockComputerUsage.log
            echo " " >> /Library/Logs/BlockComputerUsage.log
        fi

        # Delay to ensure initialization.
        sleep 10 > /dev/null

    fi

    # Prevent extra users.
    dscl . list /Users | grep -v "^_" | while read -r line
    do
        if [ $line != $main_user ] &&
           [ $line != "daemon"   ] &&
           [ $line != "nobody"   ] &&
           [ $line != "root"     ]
        then
            echo "> Deleting user '$line'." >> /Library/Logs/BlockComputerUsage.log
            dscl . -delete /Users/$line >> /Library/Logs/BlockComputerUsage.log
        fi
    done

    # Prevent extra user folders.
    ls /Users | while read -r line
    do
        if [ $line != $main_user   ] &&
           [ $line != "Shared"     ] &&
           [ $line != ".localized" ]
        then
            echo "> Deleting user folder '$line'." >> /Library/Logs/BlockComputerUsage.log
            rm -rf /Users/$line >> /Library/Logs/BlockComputerUsage.log
        fi
    done

    # Prevent unmonitored browser use.
    tmp=$(ps aux)
    if (( 10#$( echo $tmp | grep -c -i Edge.app ) > 0 ))
    then
        echo "> Killing Microsoft Edge browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i Edge.app -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i firefox ) > 0 ))
    then
        echo "> Killing Firefox browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i firefox -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i brave ) > 0 ))
    then
        echo "> Killing Brave browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i brave -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i opera ) > 0 ))
    then
        echo "> Killing Opera browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i opera -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i onion ) > 0 ))
    then
        echo "> Killing Onion browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i onion -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i chromium ) > 0 ))
    then
        echo "> Killing Chromium browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i chromium -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i vivaldi ) > 0 ))
    then
        echo "> Killing Vivaldi browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i vivaldi -9 > /dev/null
    fi
    if (( 10#$( echo $tmp | grep -c -i browser ) > 0 ))
    then
        echo "> Killing other browser." >> /Library/Logs/BlockComputerUsage.log
        pkill -f -i browser -9 > /dev/null
    fi

    # Prevent unmonitored DNS. (Lock to CleanBrowsing Family)
    tmp1=$(scutil --dns | grep nameserver | grep -c 185.228.168.168)
    tmp2=$(scutil --dns | grep nameserver | grep -c 185.228.169.168)
    tmp3=$(scutil --dns | grep -c nameserver)
    if (( 10#$tmp1 < 2 )) || (( 10#$tmp2 < 2 )) || (( 10#$tmp3 > 4 ))
    then
        echo $tmp1
        echo $tmp2
        echo $tmp3
        echo "> Resetting DNS servers." >> /Library/Logs/BlockComputerUsage.log
        networksetup -setdnsservers Wi-Fi 185.228.168.168 185.228.169.168 > /dev/null
        networksetup -setdnsservers Ethernet 185.228.168.168 185.228.169.168 > /dev/null
    fi

    sleep 1 > /dev/null

done

