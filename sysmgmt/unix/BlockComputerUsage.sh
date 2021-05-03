#!/bin/sh

# Run forever.
echo "Starting BlockComputerUsage.sh..." > /Library/Logs/BlockComputerUsage.log
while [ 1 ]
do
    
    # Fetch time and date info.
    hr=$(date +%H)
    dow=$(date +%A)
    
    # Shutdown computer, if needed.
    if (( 10#$hr < 7 )) || (( 10#$hr >= 23 ))
    then
        echo "Shutting down." >> /Library/Logs/BlockComputerUsage.log
        shutdown -h now  >> /Library/Logs/BlockComputerUsage.log
    
    # Block apps, if needed.
    elif (( 10#$hr < 9 )) || (( 10#$hr >= 19 )) || [[ $dow = "Saturday" ]] || [[ $dow = "Sunday" ]]
    then
        
        # Block Google Chrome.
        pid=$(pgrep -x "Google Chrome")
        if [ -z "$pid" ]
        then
            echo "" >> /dev/null
        else
            echo "Chrome blocked." >> /Library/Logs/BlockComputerUsage.log
            killall Google\ Chrome >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi

        # Block Visual Studio Code.
        pid=$(pgrep -x "Electron")
        if [ -z "$pid" ]
        then
            echo "" >> /dev/null
        else
            echo "VSCode blocked." >> /Library/Logs/BlockComputerUsage.log
            killall Electron >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi

        # Block TextEdit.
        pid=$(pgrep -x "TextEdit")
        if [ -z "$pid" ]
        then
            echo "" >> /dev/null
        else
            echo "TextEdit blocked." >> /Library/Logs/BlockComputerUsage.log
            killall TextEdit >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi

        # Block Notes.
        pid=$(pgrep -x "Notes")
        if [ -z "$pid" ]
        then
            echo "" >> /dev/null
        else
            echo "Notes blocked." >> /Library/Logs/BlockComputerUsage.log
            killall Notes >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi
        
        # Block ZSH.
        pid=$(pgrep -x "zsh")
        if [ -z "$pid" ]
        then
            echo "" >> /dev/null
        else
            echo "ZSH blocked." >> /Library/Logs/BlockComputerUsage.log
            killall zsh >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi

        # Block System Preferences.
        pid=$(pgrep -x "System Preferences")
        if [ -z "$pid" ]
        then
            echo "" /dev/null
        else
            echo "System Preferences blocked." >> /Library/Logs/BlockComputerUsage.log
            killall System\ Preferences >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi
        
        # Block Terminal.
        pid=$(pgrep -x "Terminal")
        if [ -z "$pid" ]
        then
            echo "" >> /dev/null
        else
            echo "Terminal blocked." >> /Library/Logs/BlockComputerUs$
            killall Terminal >> /Library/Logs/BlockComputerUsage.log
            kill -9 $pid >> /Library/Logs/BlockComputerUsage.log
        fi

    # Do nothing and sleep.
    else
        echo "" > /dev/null
    fi
    sleep 0.1 > /dev/null


done
