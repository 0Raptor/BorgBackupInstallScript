#!/bin/bash
clear
echo "BorgBackup Client Setup - Client-Server"

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
echo "#                Configuring Server Access                  #"
echo "#############################################################"
echo "You need to create a user with the server installer first!"
echo "Collecting data..."
echo " Enter backup server's IP/ FQDN"
read hostaddress
echo " Enter backup server's SSH port"
read hostport
echo " Enter backupuser name"
read hostuser
echo " Enter hostname alias for backup server (recommended: backup)"
read hostname
echo "Done."
echo ""
echo "Generating private SSH-Key..."
echo " Enter key name (recommended: backupserver - don't use spaces)"
read keyname
echo " Enter type (recommended: RSA)"
read keytype
echo " Enter key length (recommended: 2048)"
read keylen
mkdir -p /root/.ssh
ssh-keygen -f /root/.ssh/$keyname -t $keytype -b $keylen -P ""
echo "Done."
echo ""
echo "Showing public key (to enter at server installation)..."
while read line; do echo $line; done < /root/.ssh/$keyname.pub
echo Done.
echo "Updating root's ssh config..."
echo "Host $hostname" >> /root/.ssh/config
echo "    HostName $hostaddress" >> /root/.ssh/config
echo "    Port $hostport" >> /root/.ssh/config
echo "    User $hostuser" >> /root/.ssh/config
echo "    IdentityFile ~/.ssh/$keyname" >> /root/.ssh/config
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
echo " Enter BorgBackup-Server repository path"
read repopath
echo " Enter BorgBackup-Server-repository passphrase"
read repopsw
echo " Select compression for backups (1-22) [1 high speed, low compression and load - 22 low speed, high compression and load"
read repocomp
echo " Include database backups (y/n) [yes/no - tested with mariadb]"
read includedb
echo "Done."
echo ""
echo "Creating directory for backup information"
mkdir -p $backupdir/dbdumps
echo "Done."
echo ""
echo "Adding cronjob..."
crontab -l | { cat; echo "$cronargs $backupdir/backup.sh > /dev/null 2>&1"; } | crontab - #optaining current cron config, adding the new line, piping back to cron to save
echo "Done."
echo "Creating files to store backup instructions..."
touch $backupdir/backup.sh
chown root:root $backupdir/backup.sh #make sure file is only readeble to root, 'cause it contains the passphrase
chmod 0700 $backupdir/backup.sh
touch $backupdir/dbdump.sh
chown root:root $backupdir/dbdump.sh
chmod 0700 $backupdir/dbdump.sh
echo "Done."
echo ""
echo "Writing main executable"
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

echo "###### Starting backup on \$(date) ######"


##
## Create list of installed software
##

dpkg --get-selections > $backupdir/software.list


##
## Create database dumps
##

echo "Creating database dumps ..."
/bin/bash $backupdir/dbdump.sh


##
## Sync backup data
##

echo "Syncing backup files ..."
borg create --verbose --stats --list --compression zstd,$repocomp      \\
    ::'{now:%Y-%m-%d_%H:%M}'                			\\
    /home							\\
    /root	                                        	\\
    /etc                                                	\\
    /var


echo "###### Finished backup on \$(date) ######"
EOT
echo "Done."
echo ""
if [ "$includedb" = "y" ]
then
echo "Collecting information for database backups..."
echo "  You need a mysql-user that can lock and access all databases you want to include (refer to README.md)."
echo " Enter mysql user"
read dbusr
echo " Enter mysql user's password"
read dbpsw
echo " Enter databases to backup (seperated by a space)"
read dbs
echo "Done."
echo "Writing database backup..."
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash

DBUSER="$dbusr"
DBPASSWD="$dbpsw"
DBBAKPATH="$backupdir/dbdumps/"

DBS="$dbs"

for DBNAME in \$DBS; do echo "Creating backup for database \$DBNAME" && mysqldump -u \$DBUSER -p\$DBPASSWD \$DBNAME > \$DBBAKPATH "\$DBNAME.sql"; done

EOT
echo "Done."
else
echo "Writing database backup..."
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash
EOT
echo "Done."
fi

echo ""
echo "Finished installation and configuration."
echo "66896480727376738064726576667371"
