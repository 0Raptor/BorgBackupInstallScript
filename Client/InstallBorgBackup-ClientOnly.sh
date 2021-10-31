#!/bin/bash
clear # clear the console window
echo "BorgBackup Client Setup - Client-Server" # write text after echo to command line

echo ""
# make sure the script was executed as root (by comparing the uid) --> if not, inform the user and restart the script as root (exec sudo ...)
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required to setup and configure BorgBackup."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "Please make sure you have read and understand what this script does to avoid wrong inputs that may damage your system."
echo "Your inputs will not be validated. I do not assume  any liability."
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
# reads user input from the command line and saves it as the variable $repopath
read repopath
# create a directory to store the backups. -p disables warnings if the dir already existed and makes it possible to create multiple nested folders at once
mkdir -p $repopath
# initialize a new BorgBackup repository through their own program
borg init --encryption=repokey $repopath
# User will be prompted to enter a passphrase --> very important
echo "Done."
echo ""
echo "Exporting backup key..."
# Backup-Key is located in the repository. But if it gets corrupted the access all data
# will be denied. This Key CANNOT decrypt the backup-data without the pass phrase
echo " Enter file path to store backup key"
read keypath
# export the encryption key from the specified repository to the given path
borg key export $repopath $keypath
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
echo " Enter BorgBackup-Server-repository passphrase"
read repopsw
echo " Select compression for backups (1-22) [1 high speed, low compression and load - 22 low speed, high compression and load"
read repocomp
echo " Include database backups (y/n) [yes/no - tested with mariadb]"
read includedb
echo "Done."
echo ""
echo "Creating directory for backup information"
# create a directory to store backups and dumps. -p disables warnings if the dir already existed and makes it possible to create multiple nested folders at once
mkdir -p $backupdir/dbdumps
echo "Done."
echo ""
echo "Adding cronjob..."
# obtaining current cron config (crontab -l), adding the new line (echo) to the existing ones (cat), piping (|) back to cron to save (crontab -)
crontab -l | { cat; echo "$cronargs $backupdir/backup.sh > /dev/null 2>&1"; } | crontab -
echo "Done."
echo "Creating files to store backup instructions..."
# make sure files are created and only readable to root, 'cause they contain passphrases
touch $backupdir/backup.sh # create empty file
chown root:root $backupdir/backup.sh # appoint root as owner
chmod 0700 $backupdir/backup.sh # set file permissions: user root can do everything with the file (7), group root and other users nothing (00)
touch $backupdir/dbdump.sh
chown root:root $backupdir/dbdump.sh
chmod 0700 $backupdir/dbdump.sh
echo "Done."
echo ""
echo "Writing main executable"
# creating a "here-document" (EOT - EOT), but writing it into the specified file (>>) instead of showing it on the console (cat)
cat <<EOT >> $backupdir/backup.sh
#!/bin/bash

##
## Save backup to directory - settings
##

LOG="backup.log"

export BORG_REPO="$repopath"
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
# execute different commands based on the user input
if [ "$includedb" = "y" ] # if the user entered y
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
# creating a "here-document" (EOT - EOT), but writing it into the specified file (>>) instead of showing it on the console (cat)
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash

DBUSER="$dbusr"
DBPASSWD="$dbpsw"
DBBAKPATH="$backupdir/dbdumps/"

DBS="$dbs"

for DBNAME in \$DBS; do echo "Creating backup for database \$DBNAME" && mysqldump -u \$DBUSER -p\$DBPASSWD \$DBNAME > \$DBBAKPATH "\$DBNAME.sql"; done

EOT
echo "Done."
else # if they didn't enter y
echo "Writing database backup..."
# creating a "here-document" (EOT - EOT), but writing it into the specified file (>>) instead of showing it on the console (cat)
cat <<EOT >> $backupdir/dbdump.sh
cat <<EOT >> $backupdir/dbdump.sh
#!/bin/bash
EOT
echo "Done."
fi # end of if intersection
echo ""

echo "#############################################################"
echo "#                 Configuring Purge Jobs                    #"
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
then
echo "Collecting information for backup purges..."
echo "Creating files..."
#make sure file is created and only readable to root, 'cause it contains passphrases
touch $backupdir/purge-backup.sh
chown root:root $backupdir/purge-backup.sh
chmod 0700 $backupdir/purge-backup.sh
echo "Done."
echo ""
echo "Adding cronjob..."
# obtaining current cron config (crontab -l), adding the new line (echo) to the existing ones (cat), piping (|) back to cron to save (crontab -)
crontab -l | { cat; echo "$cronargs /home/$user/purge-backup.sh > /dev/null 2>&1"; } | crontab -
echo "Done."
echo ""
echo "Writing purge script..."
# creating a "here-document" (EOT - EOT), but writing it into the specified file (>>) instead of showing it on the console (cat)
cat <<EOT >> $backupdir/purge-backup.sh
#!/bin/bash

ROOTDIR="$backupdir"
LOG="prune-backup.log"

# copy all output to logfile
exec > >(tee -i ${LOG})
exec 2>&1

echo "###### Pruning backup on \$(date) ######"

export BORG_PASSPHRASE='$repopsw'
borg prune -v $repopath \\
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
