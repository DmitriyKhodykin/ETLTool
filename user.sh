#!/usr/bin/env bash

if [ "$EUID" -ne 0 ]
then echo "Please run with sudo"
    exit
fi

ACTION_NAME=$1

case "$ACTION_NAME" in
    -u|--user)
        read -p "Enter username : " username
        read -s -p "Enter password : " password
        egrep "^$username" /etc/passwd >/dev/null
        if [ $? -eq 0 ]; then
            echo "$username exists!"
            exit 1
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -p "$pass" "$username"
            usermod -aG sudo "$username"
            sudo chown -R "$username" "/home/$username"
            service cronicle stop
			node /opt/cronicle/bin/cronicle_useradd.js $username $password
			service cronicle start
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
        fi
    ;;
    -a|--admin)
        read -s -p "Enter Cronicle admin password : " password
    ;;
    *)
        echo "Select current action"
        echo "-u Add user account"
    ;;
esac