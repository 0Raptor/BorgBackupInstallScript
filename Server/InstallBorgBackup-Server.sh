#!/bin/bash
clear # clear the console window
echo "BorgBackup Server Setup - Client-Server" # write text after echo to command line

echo ""
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required to setup and configure BorgBackup."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "This script installs software and edits the ssh configuration of your system. Please make sure you have read and understand what this script does to avoid wrong inputs that may damage your system."
echo "Your inputs will not be validated. I do not assume  any liability."
echo ""

echo "You need to run the installer for server and client simultaneously!"
echo ""

echo "#############################################################"
echo "#                  Software Installation                    #"
echo "#############################################################"
echo "Updating apt..."
apt update # update local repository info (in case it was never/ a  long time ago done on the machine)
echo "Done."
echo ""
echo "Installing BorgBackup..."
apt install borgbackup # install the package "borgbackup"
echo "Done."
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
echo "Creating user for backups..."
echo " Enter name for backupuser (recommended: backupuser)"
read user
# creates a new user on the system with the specified name --> dialogue from the program adduser
adduser $user
echo "Done."
echo ""
echo "Granting permissions on repository..."
# appoint the new user as owner of the backup-repository's directory and subdirectory owner
chown -R $user:$user $bupath
echo "Done."
echo ""
echo "Adding SSH-Public-Key for user..."
echo " Enter public SSH-Key generated in in client installation process"
read sshkey
echo "Done."
echo ""
echo "Adding key to authorized_keys..."
# create a directory to store ssh configurations. -p disables warnings if the dir already existed and makes it possible to create multiple nested folders at once
mkdir -p /home/$user/.ssh
echo "command=\"borg serve --restrict-to-path $bupath --append-only\" $sshkey" >> /home/$user/.ssh/authorized_keys
echo "Done."
echo ""
echo "Disable password login for backupuser..."
# append (>>) the ssh server's configuration file line by line to disable password login for backupuser
echo "Match User $user" >> /etc/ssh/sshd_config
echo "    PasswordAuthentication	no" >> /etc/ssh/sshd_config
echo "Done."
echo ""

echo "#############################################################"
echo "#                     Add Purge Jobs                        #"
echo "#############################################################"
echo "Collecting data..."
echo " Delete old backups (y/n) [yes/no]"
read purge
echo " Enter cron arguments to time execution (recommended: 0 2 * * * [each day at 02:00])"
read cronargs
echo "Done."
echo ""
# execute different commands based on the user input
if [ "$purge" = "y" ]
then # if the user entered y
echo "Collecting information for backup purges..."
echo " Enter BorgBackup repository password"
read repopsw
echo "Done."
echo ""
echo "Creating files..."
#make sure files are created and only readable to root, 'cause they contain passphrases
touch /home/$user/purge-backup.sh # create empty file
chown root:root /home/$user/purge-backup.sh # appoint root as owner
chmod 0700 /home/$user/purge-backup.sh # set file permissions: user root can do everything with the file (7), group root and other users nothing (00)
echo "Done."
echo ""
echo "Adding cronjob..."
#obtaining current cron config (crontab -l), adding the new line (echo) to the existing ones (cat), piping (|) back to cron to save (crontab -)
crontab -l | { cat; echo "$cronargs /home/$user/purge-backup.sh > /dev/null 2>&1"; } | crontab -
echo "Done."
echo ""
echo "Writing purge script..."
# creating a "here-document" (EOT - EOT), but writing it into the specified file (>>) instead of showing it on the console (cat)
cat <<EOT >> /home/$user/purge-backup.sh
#!/bin/bash

ROOTDIR="/home/$user/"
LOG="prune-backup.log"

# copy all output to logfile
exec > >(tee -i ${LOG})
exec 2>&1

echo "###### Pruning backup on \$(date) ######"

export BORG_PASSPHRASE='$repopsw'
borg prune -v $bupath \\
--keep-daily=7 \\
--keep-weekly=4 \\
--keep-monthly=6

echo "###### Pruning finished ######"
EOT
echo "Done."
else # if they didn't enter y
echo "Skipped purge script."
fi # end of if intersection

echo ""
echo "Finished installation and configuration."
echo "66896480727376738064726576667371"
