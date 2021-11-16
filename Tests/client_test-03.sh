#!/bin/bash

# Test03 - Restore a backup (& delete sample file)

# Please enter your setup information here
#  specify path of the backup archive - make sure to add 'ssh://<servername>' in front of the path when using a remote archive
backuparchive="ssh://backup/bu/dhge"

echo "Test03 - Delete dummy file and restore it from backup"
echo " Deleting dummy file..."
#remove dummy file
rm /root/dummy.txt
echo " Done."
echo " Switch to root-directory..."
#change directory to the root directory so dummy file will be extracted to the correct path
cd /
echo " Done."
echo " Restoring dummy file..."
#extract dummy file from borg archive
borg extract $backuparchive /root/dummy.txt
echo " Done."
