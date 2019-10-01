#!/bin/bash

# Set connection variables.
username="[BOX_USERNAME]"
password="[BOX_FTP_PASSWORD]"
server="ftps://ftp.box.com:990"

# Detect command-line parameters.
if [ "$2" == "" ]; then
    echo -e "\033[0;31mError! No command-line parameters detected.\033[0m"
    echo -e "USAGE: syncBox.sh [-d|-u] Directory/To/Copy\n"
    exit 1
fi

# Copy down files from Box.
if [ "$1" == "-d" ]; then
    directories="${2} ~/${2}"

# Copy files up to Box.
elif [ "$1" == "-u" ]; then
    directories="--reverse ~/${2} ${2}"

# Invalid command-line options.
else
    echo -e "\033[0;31mError! Incorrect command-line parameters detected.\033[0m"
    echo -e "USAGE: syncBox.sh [-d|-u] Directory/To/Copy\n"
    exit 1
fi

# Connect and copy files to/from Box.
lftp -c "open -e \"set ftps:initial-prot ''; \
    set ftp:ssl-force true; \
    set ftp:ssl-protect-data true; \
    open $server; \
    user $username $password; \
    mirror --parallel --delete --only-newer --no-perms --verbose $directories;\" "

exit 0
