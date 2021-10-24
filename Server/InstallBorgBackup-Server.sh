#!/bin/bash
clear
echo "BorgBackup Server Setup - Client-Server"

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
apt update
echo "Done."
echo ""
echo "Installing BorgBackup..."
apt install borgbackup
echo "Done."
echo ""

echo "#############################################################"
echo "#               Configuring Backup Location                 #"
echo "#############################################################"
echo "Creating BorgBackup repository..."
echo " Enter folder path to store backups (path will be crated)"
read bupath
mkdir -p $bupath
borg init --encryption=repokey $bupath
# User will be prompted to enter a passphrase --> very important
echo "Done."
echo ""
echo "Exporting backup key..."
# Backup-Key is located in the repository. But if it gets corrupted the access all data
# will be denied. This Key CANNOT decrypt the backup-data without the pass phrase
echo " Enter file path to store backup key"
read keypath
borg key export $bupath $keypath
echo "Done."
echo ""

echo "#############################################################"
echo "#                Configuring Client Access                  #"
echo "#############################################################"
echo "Creating user for backups..."
echo " Enter name for backupuser (recommended: backupuser)"
read user
adduser $user
echo "Done."
echo ""
echo "Granting permissions on repository..."
chown -R $user:$user $bupath
echo "Done."
echo ""
echo "Adding SSH-Public-Key for user..."
echo " Enter public SSH-Key generated in in client installation process"
read sshkey
echo "Done."
echo ""
echo "Adding key to authorized_keys..."
mkdir -p /home/$user/.ssh
echo "command=\"borg serve --restrict-to-path $bupath --append-only\" $sshkey" >> /home/$user/.ssh/authorized_keys
echo "Done."
echo ""
echo "Disable password login for backupuser..."
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
if [ "$purge" = "y" ]
then
echo "Collecting information for backup purges..."
echo " Enter BorgBackup repository password"
read repopsw
echo "Done."
echo ""
echo "Creating files..."
touch /home/$user/purge-backup.sh
chown root:root /home/$user/purge-backup.sh #make sure file is only readeble to root, 'cause it contains the passphrase
chmod 0700 /home/$user/purge-backup.sh
echo "Done."
echo ""
echo "Adding cronjob..."
crontab -l | { cat; echo "$cronargs /home/$user/purge-backup.sh > /dev/null 2>&1"; } | crontab - #optaining current cron config, adding the new line, piping back to cron to save
echo "Done."
echo ""
echo "Writing purge script..."
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
else
echo "Skipped purge script."
fi

echo ""
echo "Finished installation and configuration."
echo "66896480727376738064726576667371"