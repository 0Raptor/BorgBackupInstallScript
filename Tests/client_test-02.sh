#!/bin/bash

# Test02 - Perform a backup (& create a sample file)

# Please enter your setup information here
#  location of the created backupscript (inside the specified 'folder to store backup information')
backupscript="/root/backup/backup.sh"

echo "Test02 - Create dummy file and perform backup"
echo " Creating dummy file..."
#write dummy text inside a file that will be included in the backup so it can be deleted and restored in the 3rd test
echo "I'm a dummy file in a dummy world" > /root/dummy.txt
echo " Done."
echo " Initiating backup..."
/bin/bash $backupscript
echo " Done."
