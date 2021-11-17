# BorgBackup Installation-Script
These script files can be used to install and configure [BorgBackup](https://borgbackup.readthedocs.io/en/stable/) on a Linux system (tested under Ubuntu). During installation, the parameters must be entered by the user.

There are two basic configuration options:
- Client server (the client saves its backups on the hard disk of an external server)
- Client-Only (the client stores its backups locally, e. g. on a connected hard disk)

*Die deutsche Originalversion kann unter [README.md](README.md) eingesehen werden*

## Requirements
The script requires a Linux operating system (tested with Ubuntu) to run.
The user performing the installation must have root permissions. The package '[sudo](https://linux.die.net/man/8/sudo)' should also be installed.
To install BorgBackup, the package manager '[apt](https://linux.die.net/man/8/apt)' is required.
Automated scripts are realized using the tool '[cron](https://linux.die.net/man/8/cron)'.

For the configuration with a **Server** an SSH server must be installed on it.
SSH keys are generated with the command '[ssh-keygen](https://linux.die.net/man/1/ssh-keygen)'. The tool should already be installed.

## Usage
Download script: 
```
# At the server
curl -o InstallBorgBackup-Server.sh https://raw.githubusercontent.com/0Raptor/BorgBackupInstallScript/master/Server/InstallBorgBackup-Server.sh
# At the client
curl -o InstallBorgBackup-ClientServer.sh https://raw.githubusercontent.com/0Raptor/BorgBackupInstallScript/master/Client/InstallBorgBackup-ClientServer.sh

# Only client
curl -o InstallBorgBackup-ClientOnly.sh https://raw.githubusercontent.com/0Raptor/BorgBackupInstallScript/master/Client/InstallBorgBackup-ClientOnly.sh
```

Execute script: 
```
chmod +x scriptname.sh
sudo ./scriptname.sh
```

### Testing  
#### Automatic
You can find shell scripts inside the directory "Tests". They can be downloaded and executed like the installation script.  
Keep in mind to change the parameters **inside the file**.  
The script shall be performed in the given order and on the server OR client.  
The following functions will be checked
1. Confirm SSH-Connection
2. Create a backup including a dummy file
3. Delete dummy file and recover it from backup afterwards
4. Perform a Backup-Prune

#### Manually
Before performing the backup for the first time, test the connection with `ssh backup` (or the configured server alias). After the manual confirmation of the server identity by typing `y` an empty console line should be displayed. This can be exited with Ctrl+C. If everything worked, the following message is displayed:
```
^C$LOG ERROR borg.archiver Remote: Keyboard interrupt
Connection to %SERVER% closed.
```
This confirms that the connection has been successfully established, but only implicit BorgBackup commands can be performed.

Now the backup script can be tested by executing it manually.
```
sudo su -
cd /root/backup
./backup.sh
```

If interpreter errors occur, re-adjust the encoding from Windows to Linux:
```
sed -i -e 's/\r$//' scriptname.sh
```

## Manual Configuration
The scripts will create or modify all necessary files based on user input. However, if an adjustment is needed later, the changed files are described here.
### Client
- %BackupDir%/backup.sh
	- Has instructions for the backup process
- %BackupDir%/dbdump.sh
	- Empty, if no database backups should be created
	- Has instructions for the database-backup process aka "dumps"
- Command: `sudo contab -e`
	- Schedules execution of backups/ (prunes)

### Client (Client-Only)
- %BackupDir%/prune-backups.sh
	- Has instructions for the cleaning the backups aka "prunes"
	- Obsolete or corrupted backups will be deleted

### Client (Client-Server)
- /root/.ssh/%KeyName%
	- Private SSH-Key to connect to the serevr
	- Adding the suffix '.pub' will show the public key
- /root/.ssh/config
	- IP, port, username and private-key of the backup-server are configured in this file

### Server
- /home/%BackupUser%/.ssh/authorized_keys
	- Stores the client's public SSH-Key for access
	- The content in front of the key prevents unauthorized fille access and execution of any non BorgBackup-command
		- `command="borg serve --restrict-to-path %BackupRepo% --append-only" %PublicSshKey%`
- /home/%BackupUser%/purge-backup.sh
	- Has instructions for the cleaning the backups aka "prunes"
	- Obsolete or corrupted backups will be deleted
- /etc/ssh/sshd_config
	- Prevents the Backupuser from SSH-Login via passwordauthentiication
- Command: `sudo contab -e`
	- Schedules execution of prunes
- Backup directory
	- Stores the backuped files from the clients
- Exported key
- To access the BorgBackup repository you need the password and the key file (stored in the folder)
- If the repository is partially damaged (especially the key file), the intact data cannot be recovered --> to prevent that case the key file should be exported and kept securely

## Functions
Some functions of the backup script are set up by default, others require a previous configuration of the system.

### Default Backups
The unadapted backup script backs up the following data:
- A list of all installed packages
- The directories
	- /home
	- /root
	- /etc
	- /var
- (if configured) an additional database dump of all databases specified during installation

### Database Backups
A special database user is needed to ’dump' the data.
Username and password can be customized as desired.
```
mysql -u root -p
create user 'backup'@'localhost' identified by 'backupuserpassword';
grant SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER on *.* to 'backup'@'localhost';
quit;
```
If this is configured, the login data and database names can be specified during the installation.

## Inspiration
https://borgbackup.readthedocs.io/en/stable/quickstart.html  
https://thomas-leister.de/server-backups-mit-borg/

## License
Licensed under GNU General Public License v3.0!  
This script was written in the course of a university work.
&nbsp;  
&nbsp;  
&nbsp;  
&nbsp;  
# Usage of BorgBackup
## Recovery from Backups
The generated backups can be restored at any time in the event of a system failure or accidental deletion.

### From Server
Recover files from the server. Should be called from the file system root, since the backup folder structure is replicated in the current folder. With PATH you can optionally select a single folder, a single file (or several by wildcards). Otherwise, everything will be restored.
```
borg extract ssh://[HOST]/[REPOSITORY PATH] ([PATH])
```

### From Client

Recover files from local hard drive. Should be called from the file system root, since the backup folder structure is replicated in the current folder. With PATH you can optionally select a single folder, a single file (or several wildcards). Otherwise, everything will be restored.
```
borg extract [REPOSITORY PATH] ([PATH])
```

## Replace Corrupted Key
The installation process exports a key that is essential for the use of the backup repositories. If it is damaged in the backup repository, the exported one can be imported again using the following command.
```
borg key import [REPOSITORY PATH] [BACKUP KEY PATH]
```
