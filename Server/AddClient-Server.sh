#!/bin/bash
clear # clear the console window
echo "BorgBackup Server - Add Client" # write text after echo to command line

echo ""
# make sure the script was executed as root (by comparing the uid) --> if not, inform the user and restart the script as root (exec sudo ...)
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required to setup and configure BorgBackup."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "This edits the ssh configuration of your system. Please make sure you have read and understand what this script does to avoid wrong inputs that may damage your system."
echo "You should only run this script if you used the InstallBorgBackup-Server.sh before!"
echo "Your inputs will not be validated. I do not assume any liability."
echo ""

echo "You need to run the installer on the client and this script simultaneously!"
echo ""

echo "#############################################################"
echo "#               Configuring Backup Location                 #"
echo "#############################################################"
echo "Creating BorgBackup repository..."
echo " Enter folder path to store backups (path will be crated)"
# reads user input from the command line and saves it as the variable $bupath
read bupath
# create a directory to store the backups. -p disables warnings if the dir already existed and makes it possible to create multiple nested folders at once
mkdir -p $bupath
# initialize a new BorgBackup repository through their own program
borg init --encryption=repokey $bupath
# User will be prompted to enter a passphrase --> very important
echo "Done."
echo ""
echo "Exporting backup key..."
# Backup-Key is located in the repository. But if it gets corrupted the access all data
# will be denied. This Key CANNOT decrypt the backup-data without the pass phrase
echo " Enter file path to store backup key"
read keypath
# export the encryption key from the specified repository to the given path
borg key export $bupath $keypath
echo "Done."
echo ""

echo "#############################################################"
echo "#                Configuring Client Access                  #"
echo "#############################################################"
echo "Collecting data..."
echo " Enter name of your system's backupuser"
read user
echo "Done."
echo ""
echo "Granting permissions on repository..."
# appoint the user as owner of the backup-repository's directory and subdirectory
chown -R $user:$user $bupath
echo "Done."
echo ""
echo "Adding SSH-Public-Key for user..."
echo " Enter public SSH-Key generated in in client installation process"
read sshkey
echo "Done."
echo ""
echo "Adding key to authorized_keys..."
echo "command=\"borg serve --restrict-to-path $bupath --append-only\" $sshkey" >> /home/$user/.ssh/authorized_keys
echo "Done."
echo ""

echo "#############################################################"
echo "#                     Add Purge Jobs                        #"
echo "#############################################################"
echo "Collecting data..."
echo " Delete old backups (y/n) [yes/no]"
read purge
echo "Done."
echo ""
# execute different commands based on the user input
if [ "$purge" = "y" ]
then # if the user entered y
echo "Annotation!"
echo " This script will open the purge-configuration file in the text-editor nano."
echo " Please copy and paste everything from '\"echo "###### Prune' to '--keep-monthly=6' and paste in a new line above the 'echo "#####Pruning finished' statement."
echo " Than change the passphrase in the '' to the just created one and the path after the '-v' to the new created repository path."
echo " To save your changes press Ctrl+O, Enter and Ctrl+X."
echo "Press Enter to continue..."
echo ""
read
echo "Updating files..."
# open the configuration file in the text editor nano so the user can change the configuration
nano /home/$user/purge-backup.sh
echo "Done."
else # if they didn't enter y
echo "Skipped purge script."
fi # end of if intersection

echo ""
echo "Finished configuration."
echo "66896480727376738064726576667371"
