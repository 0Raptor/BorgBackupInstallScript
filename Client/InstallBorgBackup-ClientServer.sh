#!/bin/bash
clear
echo "BorgBackup Client Setup - Client-Server"

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
echo "#                Configuring Server Access                  #"
echo "#############################################################"
echo "You need to create a user with the server installer first!"
echo "Collecting data..."
echo " Enter backupservers IP/ FQDN"
read hostaddress
echo " Enter backupservers SSH port"
read hostport
echo " Enter backupuser name"
read hostuser
echo " Enter hostname alias for backupserver (recommended: backup)"
read hostname
echo "Done."
echo ""
echo "Generation private SSH-Key..."
echo " Enter key name (recommended: backupserver - don't use spaces)"
read keyname
echo " Enter type (recommended: RSA)"
read keytype
echo " Enter key length (recommended: 2048)"
read keylen
echo " Enter password (leave blank for none)"
read keypsw
ssh-keygen -f ~/.ssh/$keyname -t $keytype -b $keylen -p $keypsw
echo "Done."
echo ""
echo "Showing public key (to enter in server installation)..."
while read line; do echo $line; done < $keyname.pub
echo Done.
echo "Updaten root's ssh config..."
echo "Host $hostname" >> /root/.ssh/config
echo "\tHostName $hostaddress" >> /root/.ssh/config
echo "\tPort $hostport" >> /root/.ssh/config
echo "\tUser $hostuser" >> /root/.ssh/config
echo "\tIdentityFile ~/.ssh/$keyname" >> /root/.ssh/config
echo "Done."
echo ""

echo "#############################################################"
echo "#                  Configuring Backup Jobs                  #"
echo "#############################################################"
echo "Collecting data..."
echo " Enter folder to store backup information (recommended: /root/backup)"
read backupdir
echo " Enter cron arguments to time execution (recommended: @daily [each day at 00:00] or 0 0 * * *)"
read cronargs
echo " Enter BorgBackup-Server reposotory path"
read repopath
echo " Enter BorgBackup-Server-Reposotory passphrase"
read repopsw
echo " Select compression for backups (1-22) [1 high speed, low compression and load - 22 low speed, high compression and load"
read repocomp
echo " Include database backups (y/n) [tested with mariadb]"
read includedb
echo "Done."
echo ""
echo "Creating directory for backup information"
mkdir -p $backupdir/dbdumps
echo "Done."
echo ""
echo "Adding cronjob..."
crontab -l | { cat; echo "$cronargs $backupdir/backup.sh > /dev/null 2>&1"; } | crontab -
echo "Done."
echo "Creating files to store backup instructions..."
touch $backupdir/backup.sh
chown root:root $backupdir/backup.sh
chmod 0700 $backupdir/backup.sh
touch $backupdir/dbdump.sh
chown root:root $backupdir/dbdump.sh
chmod 0700 $backupdir/dbdump.sh
echo "Done."
echo ""
echo "Writing main configuration file"
cat <<EOT >> $backupdir/backup.sh
#!/bin/bash

##
## Save backup to directory - settings
##

LOG="backup.log"

export BORG_REPO="ssh://$hostname/$repopath"
export BORG_PASSPHRASE='$repopsw'

##
## Write output to logfile
##

exec > >(tee -i ${LOG})
exec 2>&1

echo "###### Starting backup on $(date) ######"


##
## Create list of installed software
##

dpkg --get-selections > /root/backup/software.list


##
## Create database dumps
##

echo "Creating database dumps ..."
/bin/bash /root/backup/dbdump.sh


##
## Sync backup data
##

echo "Syncing backup files ..."
borg create --verbose --stats --list --compression zstd,$repocomp       \
    ::'{now:%Y-%m-%d_%H:%M}'                			\
    /home							\
    /root	                                        	\
    /etc                                                	\
    /var/www						


echo "###### Finished backup on $(date) ######"
EOT
echo "Done."
echo ""
if [ "$methode" = "y" ]
then
echo "Collecting information for database backups..."
echo "  You need a mysql-user that can lock and access all databases you want to include (refer to README.md)."
echo " Enter mysql user"
read dbusr
echo " Enter mysql user's password"
read dbpsw
echo " Enter databases to backup (seperated by space)"
read dbs
echo "Done."
echo "Writing database backup..."
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash

DBUSER="$dbusr"
DBPASSWD="$dbpsw"
DBBAKPATH="/root/backup/dbdumps/"

DBS="$dbs"

for DBNAME in $DBS; do echo "Creating backup for database $DBNAME" && mysqldump -u $DBUSER -p$DBPASSWD $DBNAME > $DBBAKPATH"$DBNAME.sql"; done

EOT
echo "Done."
else
echo "Writing database backup..."
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash
EOT
echo "Done."
fi
