#!/bin/bash

# Test01 - Perform a purge

# Please enter your setup information here
#  location of the created purgescript (inside the home directory of the backupuser)
backupscript="/home/backupuser/purge-backup.sh"

echo "Test01 - Purge backups"
echo " Initiating purge..."
/bin/bash $backupscript
echo " Done."
