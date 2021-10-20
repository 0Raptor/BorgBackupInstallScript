# BorgBackup Installation Script
abc

## Anforderungen
abc

## Verwendungen
abc

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
https://thomas-leister.de/server-backups-mit-borg/
https://borgbackup.readthedocs.io/en/stable/quickstart.html