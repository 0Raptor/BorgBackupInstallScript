# BorgBackup Installation Script
abc

## Anforderungen
abc

## Verwendungen
Skript downloaden: 
``

Skript starten: 
```
chmod +x scriptname.sh
sudo ./scriptname.sh
```

Vor dem ersten durchführen des Backups kann die Verbidnung mit `ssh backup` (bzw. dem konfigurierten Server-Alias) testen. Nach dem manuellen bestätigen der Serveridentität durch eingeben von `y` sollte eine leere Konsolenzeile angezeigt werden. Diese kann mit Strg+C verlassen werden. Wenn alles geklappt hat wird folgende Meldung angezeigt: 
```
^C$LOG ERROR borg.archiver Remote: Keyboard interrupt
Connection to %SERVER% closed.
```
Dies bestätigt, dass die Verbindung erfolgreich hergestellt wurde, aber nur implizite Borg-Backup Befehle eingegeben werden können. 

Das Backup-Skript kann durch manuelles ausführen getestet werden.
```
sudo su -
cd /root/backup
./backup.sh
```

Wenn Interpreter-Fehler auftreten die Encodierung erneut von Windows auf Linux anpassen: 
`sed -i -e 's/\r$//' scriptname.sh`

## Funktionen
abc

### Database Backup
Es wird ein spezieller Datenbank-Benutzer benötigt, um die Daten zu 'dumpen'. 
Benutzername und Passwort können nach Belieben angepasst werden. 
```
mysql -u root -p
create user 'backup'@'localhost' identified by 'backupuserpassword';
grant SELECT, RELOAD, LOCK TABLES, REPLICATION CLIENT, SHOW VIEW, EVENT, TRIGGER on *.* to 'backup'@'localhost';
quit;
```

## Inspiration
https://borgbackup.readthedocs.io/en/stable/quickstart.html
https://thomas-leister.de/server-backups-mit-borg/
