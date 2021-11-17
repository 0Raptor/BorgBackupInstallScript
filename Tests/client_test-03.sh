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
echo " List all backups..."
borg list $backuparchive
echo " Done."
echo "Please select a backup from the list:"
read bu
echo " Restoring dummy file..."
#extract dummy file from borg archive
borg extract $backuparchive::$bu /root/dummy.txt
echo " Done."
