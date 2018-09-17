# OMV / TVH Script
Dieses Skript prüft ob im TVHeadend zukünftige Aufnahmen hinterlegt sind.

Für die jeweiligen Aufnahmen werden dann im Openmediavault-Wakealarms Weckzeiten für den Server hinterlegt.

Das Skript verhindert einen Shutdown durch Openmediavault-Autoshutdown, falls aktuell oder innerhalb der nächsten 90min eine Aufnahme läuft oder geplant ist.

Ein Shutdown wird ebenfalls verhindert, falls aktuell ein TV-Stream läuft.

# Voraussetzungen
* Openmediavault 3 oder 4
* Openmediavault-Autoshutdown
* Openmediavault-Wakealarms
* TVHeadend 4.2
* Debian

In den Autoshutdown Einstellungen muss unter "Erweiterte Optionen" folgendes eingetragen werden: PLUGINCHECK="true"

# Variablen
* **tvh_login** Benutzername von TVHeadend
* **tvh_password** Passwort von TVHeadend
* **tvh_ip_port** IP/Port von TVHeadend
* **boot_pre_dvr** Zeit in Sekunden in welcher das System vor einer Aufnahme booten soll
* **no_sleep_pre_boot** Zeit in Sekunden in welcher das System vor einer Aufnahme nicht herunterfahren soll

# Herunterladen TVHeadend AutoShutdown Datei
```
cd /etc/autoshutdown.d/
sudo wget https://raw.githubusercontent.com/Peppi87/TVH_OMV/master/etc/autoshutdown.d/tvheadend
```

# Herunterladen Skript
```
cd $HOME
wget https://raw.githubusercontent.com/Peppi87/TVH_OMV/master/check_tvh.sh
chmod 755 check_tvh.sh
```

# Ausführen
```
./check_tvh.sh
```

Das Skript kann dann über Openmediavault-> Geplante Aufgaben im 5min Rhythmus ausgeführt werden.
Oder per Crontab: */5 * * * * /root/check_tvh.sh
