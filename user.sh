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
			node /opt/cronicle/bin/useradd.js $username $password
			service cronicle start
            sudo -u postgres bash -c "psql -c \"CREATE USER ${username} WITH ENCRYPTED PASSWORD '${password}';\""
		    sudo -u postgres bash -c "psql -c \"CREATE DATABASE ${username};\""
		    sudo -u postgres bash -c "psql -c \"GRANT ALL PRIVILEGES ON DATABASE ${username} TO ${username};\""
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
        fi
    ;;
    -a|--admin)
        read -s -p "Enter Cronicle admin password : " password
        service cronicle stop
		node /opt/cronicle/bin/storage-cli.js admin admin "$password"
		service cronicle start
    ;;
    -c|--change)
        read -p "Enter username : " username
        read -s -p "Enter new password : " password
        echo -e "${password}\n${password}" | passwd ${username}
        sudo -u postgres bash -c "psql -c \"ALTER USER ${username} WITH ENCRYPTED PASSWORD '${password}';\""
    ;;
    *)
        echo "Select current action"
        echo "-u Add user account"
    ;;
esac