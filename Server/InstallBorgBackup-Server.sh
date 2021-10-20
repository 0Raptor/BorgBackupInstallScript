#!/bin/bash
clear
echo "BorgBackup Server Setup - Client-Server"

echo ""
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required to setup and configure BorgBackup."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "This script installs software and edits the ssh configuration of your system. Please make sure you have read and understand what this script does to avoid wrong inputs that may damage your system."
echo "Your inputls will not be validatet. I do not assume  any liability."
echo ""

echo "You need to run the installer for server and client simultaneously!"
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

echo "#############################################################"
echo "#               Configuring Backup Location                 #"
echo "#############################################################"
echo "Creating BorgBackup reposotory..."
echo " Enter empty folder path to store backups"
read bupath
mkdir -p $bupath
borg init --encryption=repokey $bupath
echo "Done."
echo ""
echo "Exporting backup key..."
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
echo "Adding SSH-Public-Key for user..."
echo " Enter public SSH-Key generated in in client installation process"
read sshkey
echo "Done."
echo ""
echo "Adding key to authorized_keys..."
echo 'command="borg serve --restrict-to-path $bupath --append-only" $sshkey' >> /home/$user/.ssh/authorized_keys
echo "Done."
echo ""
echo "Disable password login for backupuser..."
echo "Match User $user" >> /etc/ssh/sshd_config
echo "\tPasswordAuthentication	no" >> /etc/ssh/sshd_config
echo "Done."
echo ""

echo "#############################################################"
echo "#                     Add Purge Jobs                        #"
echo "#############################################################"
echo "Collecting data..."
echo " Delete old backups (y/n)"
read purgeu
echo " Enter cron arguments to time execution (recommended: 0 2 * * * [each day at 02:00])"
read cronargs
echo "Done."
echo ""
if [ "$methode" = "y" ]
then
echo "Collecting information for backup purges..."
echo " Enter BorgBackup reposotory password"
read repopsw
echo "Done."
echo ""
echo "Creating files..."
touch /home/$user/purge-backup.sh
chown root:root /home/$user/purge-backup.sh
chmod 0700 /home/$user/purge-backup.sh
echo "Done."
echo ""
echo "Adding cronjob..."
crontab -l | { cat; echo "$cronargs /home/$user/purge-backup.sh > /dev/null 2>&1"; } | crontab -
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

echo "###### Pruning backup on $(date) ######"

export BORG_PASSPHRASE='$repopsw'
borg prune -v $bupath \
--keep-daily=7 \
--keep-weekly=4 \
--keep-monthly=6

echo "###### Pruning finished ######"
EOT
echo "Done."
else
echo "Writing database backup..."
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash
EOT
echo "Done."
fi
