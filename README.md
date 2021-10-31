# BorgBackup Installations-Skript
Diese Skript-Dateien können zur Installation und Konfiguration von [BorgBackup](https://borgbackup.readthedocs.io/en/stable/) auf einem Linux-System eingesetzt werden (getestet unter Ubuntu). Während der Installation müssen die Parameter durch den Benutzer eingegeben werden.  
  
Es gibt zwei grundlegende Konfigurationsoptionen:
- Client-Server (der Client speichert seine Backups auf der Festplatte eines externen Servers)
- Client-Only (der Client speichert seine Backups lokal ab, z. B. auf einer angeschlossenen Festplatte)

*An English translation is available at [README_EN.md](README_EN.md)*

## Anforderungen
Das Skript erfordert ein Linux-Betriebssystem (getestet mit Ubuntu), um ausgeführt zu werden.  
Der Benutzer, der die Installation vornimmt, muss über root-Berechtigungen verfügen. Das Paket '[sudo](https://linux.die.net/man/8/sudo)' sollte zudem installiert sein.  
Zur Installation von BorgBackup wird der Paketmanager '[apt](https://linux.die.net/man/8/apt)' benötigt.  
Automatisierte Skripte werden über das Tool '[cron](https://linux.die.net/man/8/cron)' realisiert.  
  
Für die Konfiguration mit einem **Server** muss auf diesem ein SSH-Server installiert sein.  
SSH-Keys werden mit dem Befehl '[ssh-keygen](https://linux.die.net/man/1/ssh-keygen)' erzeugt. Das entsprechende Tool sollte bereits installiert sein.

## Verwendungen
Skript downloaden: 
```
# Auf dem Server
curl -o InstallBorgBackup-Server.sh https://raw.githubusercontent.com/0Raptor/BorgBackupInstallScript/master/Server/InstallBorgBackup-Server.sh
# Auf dem Client
curl -o InstallBorgBackup-ClientServer.sh https://raw.githubusercontent.com/0Raptor/BorgBackupInstallScript/master/Client/InstallBorgBackup-ClientServer.sh

# Nur Client
curl -o InstallBorgBackup-ClientOnly.sh https://raw.githubusercontent.com/0Raptor/BorgBackupInstallScript/master/Client/InstallBorgBackup-ClientOnly.sh
```

Skript starten: 
```
chmod +x scriptname.sh
sudo ./scriptname.sh
```

Vor dem ersten Durchführen des Backups kann die Verbindung mit `ssh backup` (bzw. dem konfigurierten Server-Alias) testen. Nach dem Manuellen bestätigen der Serveridentität durch Eingeben von `y` sollte eine leere Konsolenzeile angezeigt werden. Diese kann mit Strg+C verlassen werden. Wenn alles geklappt hat, wird folgende Meldung angezeigt: 
```
^C$LOG ERROR borg.archiver Remote: Keyboard interrupt
Connection to %SERVER% closed.
```
Dies bestätigt, dass die Verbindung erfolgreich hergestellt wurde, aber nur implizite BorgBackup-Befehle eingegeben werden können. 

Das Backup-Skript kann durch manuelles ausführen, getestet werden.
```
sudo su -
cd /root/backup
./backup.sh
```

Wenn Interpreter-Fehler auftreten, die Encodierung erneut von Windows auf Linux anpassen: 
```
sed -i -e 's/\r$//' scriptname.sh
```

## Manuelle Konfiguration
Die Skripte erstellen oder modifizieren anhand von Benutzereingaben alle nötigen Dateien. Sollte jedoch später eine Anpassung nötig sein, sind die angepassten Dateien hier beschrieben.
### Client
- %BackupDir%/backup.sh
	- Enthält die Befehle, die die Durchführung des Backups steuern
- %BackupDir%/dbdump.sh
	- Leer, wenn keine Datenbank-Backups angelegt werden sollen
	- Enthält die Befehle, die die Erstellung der Datenbank-Backups / "dumps" steuern
- Befehl: `sudo contab -e`
	- Terminiert die Ausführung der Backups/ (Prunes)

### Client (Client-Only)
- %BackupDir%/prune-backups.sh
	- Enthält die Befehle zum Aufräumen der Backups
	- Veraltete und fehlerhafte Backups werden gelöscht

### Client (Client-Server)
- /root/.ssh/%KeyName%
	- Privater SSH-Schlüssel für die Verbindung zum Server
	- Wird die Endung '.pub' angehangen kann der öffentliche Schlüssel angezeigt werden
- /root/.ssh/config
	- Es werden IP, Port, Benutzername und Private-Key des Servers gespeichert, auf den das Backup geladen werde soll

### Server
- /home/%BackupUser%/.ssh/authorized_keys
	- Speichert den öffentlichen SSH-Schlüssel, damit sich der Client einloggen kann
	- Der Inhalt vor dem Schlüssel verhindert, dass ein Client unautorisierte Befehle ausführen oder auf falsche Backups zugreifen kann
		- `command="borg serve --restrict-to-path %BackupRepo% --append-only" %PublicSshKey%`
- /home/%BackupUser%/purge-backup.sh
	- Enthält die Befehle zum Aufräumen der Backups
	- Veraltete und fehlerhafte Backups werden gelöscht
- /etc/ssh/sshd_config
	- Verhindert das Einloggen des Backupusers durch Passwortauthentifizierung
- Befehl: `sudo contab -e`
	- Terminiert die Ausführung der Prunes
- Verzeichnis für die Backups
	- Hier werden die vom Client gesicherten Dateien abgespeichert
- Exportierter Schlüssel
	- Zum Zugreifen auf die BorgBackup-Repository wird das Passwort und die Schlüssel-Datei (in dem Ordner abgelegt) benötigt
	- Sollte das Repository teilweise beschädigt werden (darunter die Schlüssel-Datei), können auch die intakten Daten nicht wieder hergestellt werden --> für den Fall sollte die Schlüssel-Datei exportiert und sicher verwahrt werden

## Funktionen
Einige Funktionen des Backupskripts werden standardmäßig eingerichtet, andere erfordern eine vorige Konfiguration des Systems.

### Standardmäßig gesicherte Dateien
Das unangepasste Backupskript sichert die folgenden Daten:
- Eine Liste aller installierten Pakete
- Die Verzeichnisse
	- /home
	- /root
	- /etc
	- /var
- (Wenn konfiguriert) einen zusätzlichen Datenbank-Dump aller bei der Installation angegebenen Datenbanken

### Datenbank Backup
Es wird ein spezieller Datenbank-Benutzer benötigt, um die Daten zu 'dumpen'. 
Benutzername und Passwort können nach Belieben angepasst werden. 
```
mysql -u root -p
create user 'backup'@'localhost' identified by 'backupuserpassword';
grant SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER on *.* to 'backup'@'localhost';
quit;
```
Ist dies konfiguriert, können die Logindaten und Datenbanknamen bei der Installation angegeben werden.

## Inspiration
https://borgbackup.readthedocs.io/en/stable/quickstart.html  
https://thomas-leister.de/server-backups-mit-borg/

## Lizenz
Lizenziert unter GNU General Public License v3.0!  
Dieses Skript entstand im Zuge einer Hochschularbeit.
&nbsp;  
&nbsp;  
&nbsp;  
&nbsp;  
# Benutzung von BorgBackup
## Wiederherstellung von Backups
Die erzeugten Backups können bei einem Systemausfall oder versehentlichen Löschen jederzeit wieder hergestellt werden.

### Von Server
Dateien vom Server wiederherstellen. Sollte aus der Dateisystem-Wurzel aufgerufen werden, da die Backup-Ordnerstruktur in dem aktuellen Ordner nachgebildet wird. Bei PATH kann optional ein einzelner Ordner, eine einzelne Datei (oder mehrere durch Wildcards) ausgewählt werden. Sonst wird alles wieder hergestellt.
```
borg extract ssh://[HOST]/[REPOSITORY PATH] ([PATH])
```

### Von Client
Dateien von lokaler Festplatte wiederherstellen. Sollte aus der Dateisystem-Wurzel aufgerufen werden, da die Backup-Ordnerstruktur in dem aktuellen Ordner nachgebildet wird. Bei PATH kann optional ein einzelner Ordner, eine einzelne Datei (oder mehrere mit Wildcards) ausgewählt werden. Sonst wird alles wieder hergestellt.
```
borg extract [REPOSITORY PATH] ([PATH])
```

## Beschädigten Key ersetzen
Beim Installationsprozess wird ein Key exportiert, der für die Benutzung der Backup-Repositories essenziell ist. Wird dieser im Repository beschädigt, kann er über folgenden Befehl wieder importiert werden.
```
borg key import [REPOSITORY PATH] [BACKUP KEY PATH]
```
