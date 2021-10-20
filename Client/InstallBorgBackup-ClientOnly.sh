#!/bin/bash
clear
echo "BorgBackup Client Setup - Client-Only"

echo ""
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required to setup and configure BorgBackup."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "This script installs software and edits the ssh configuration of your system. Please make sure you have read and understand what this script does to avoid wrong inputs that may damage your system."
echo "Your inputls will not be validatet. I do not assume  any liability."
echo ""

echo "#############################################################"
echo "#                  Software Installation                    #"
echo "#############################################################"
echo "Updateing apt..."
apt update
echo "Done."
echo ""
echo "Installing BorgBackup..."
apt install borgbackup
echo "Done."
echo ""
