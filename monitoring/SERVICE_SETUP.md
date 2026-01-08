# MEMERO Monitoring - 24/7 Service Installation

## 🎯 Zweck

Installiert das MEMERO Monitoring als systemd-Service, damit es:
- ✅ **24/7 läuft** (auch nach SSH-Disconnect)
- ✅ **Automatisch beim Server-Neustart startet**
- ✅ **Bei Absturz automatisch neu startet**
- ✅ **Logs zu systemd schreibt** (einfaches Debugging)

---

## 🚀 Installation (Einmalig)

### 1. Auf dem Server einloggen

```bash
ssh root@dein-server.de
cd /root/memero
```

### 2. Code aktualisieren

```bash
git pull
```

### 3. Service installieren

```bash
cd /root/memero/monitoring
sudo ./install_service.sh
```

Das Script:
- ✅ Erkennt automatisch dein Virtual Environment (venv/env)
- ✅ Erstellt systemd-Service mit korrekten Pfaden
- ✅ Aktiviert Auto-Start beim Boot
- ✅ Startet den Service sofort
- ✅ Zeigt Status an

---

## 📋 Service-Verwaltung

### Service starten
```bash
sudo systemctl start memero-monitor
```

### Service stoppen
```bash
sudo systemctl stop memero-monitor
```

### Service neu starten (nach Code-Update)
```bash
sudo systemctl restart memero-monitor
```

### Status prüfen
```bash
sudo systemctl status memero-monitor
```

### Logs live anzeigen
```bash
sudo journalctl -u memero-monitor -f
```

### Logs der letzten Stunde
```bash
sudo journalctl -u memero-monitor --since "1 hour ago"
```

### Alle Logs
```bash
sudo journalctl -u memero-monitor -n 200
```

---

## 🔄 Nach Code-Updates

Wenn du den Code aktualisierst (`git pull`), musst du nur den Service neu starten:

```bash
cd /root/memero
git pull
sudo systemctl restart memero-monitor
```

**Das war's!** Keine SSH-Session muss offen bleiben.

---

## 🛡️ Vorteile gegenüber manuellem Start

| Feature | Manuell (`python monitor.py`) | systemd-Service |
|---------|------------------------------|-----------------|
| Läuft nach SSH-Disconnect | ❌ Stoppt | ✅ Läuft weiter |
| Auto-Start bei Server-Neustart | ❌ Manuell starten | ✅ Automatisch |
| Auto-Restart bei Absturz | ❌ Bleibt tot | ✅ Startet neu (10s) |
| Logs | ❌ Console oder Datei | ✅ systemd journal |
| Prozess-Management | ❌ Manuell mit `ps`/`kill` | ✅ systemctl |
| Status-Übersicht | ❌ Kein Status | ✅ systemctl status |

---

## 🧪 Testen

### 1. Service läuft?
```bash
sudo systemctl status memero-monitor
```

Erwartete Ausgabe:
```
● memero-monitor.service - MEMERO Monitoring Dashboard
   Loaded: loaded (/etc/systemd/system/memero-monitor.service; enabled)
   Active: active (running) since ...
```

### 2. Dashboard erreichbar?
```bash
curl -I http://localhost:5000
```

Sollte `200 OK` zurückgeben.

### 3. SSH-Disconnect-Test
1. Service starten: `sudo systemctl start memero-monitor`
2. SSH-Verbindung trennen (Terminal schließen)
3. Neu einloggen
4. Prüfen: `sudo systemctl status memero-monitor`
   
→ Service sollte **noch laufen**! ✅

### 4. Auto-Restart-Test
```bash
# Finde PID
sudo systemctl status memero-monitor | grep "Main PID"

# Prozess killen
sudo kill -9 <PID>

# 15 Sekunden warten
sleep 15

# Status prüfen
sudo systemctl status memero-monitor
```

→ Service sollte **automatisch neu gestartet** sein! ✅

---

## 🔧 Erweiterte Konfiguration

### Service-Datei bearbeiten
```bash
sudo nano /etc/systemd/system/memero-monitor.service
```

Dann neu laden:
```bash
sudo systemctl daemon-reload
sudo systemctl restart memero-monitor
```

### Umgebungsvariablen hinzufügen

In der Service-Datei:
```ini
[Service]
Environment="VARIABLE_NAME=value"
Environment="ANOTHER_VAR=value"
```

### Restart-Policy ändern

```ini
[Service]
Restart=always           # Immer neu starten
# Restart=on-failure    # Nur bei Fehler
# Restart=no            # Nie neu starten
RestartSec=10           # Wartezeit vor Neustart (Sekunden)
```

---

## 🗑️ Deinstallation

Falls du den Service wieder entfernen willst:

```bash
cd /root/memero/monitoring
sudo ./uninstall_service.sh
```

Oder manuell:
```bash
sudo systemctl stop memero-monitor
sudo systemctl disable memero-monitor
sudo rm /etc/systemd/system/memero-monitor.service
sudo systemctl daemon-reload
```

---

## 📊 Monitoring des Services

### CPU/RAM-Nutzung
```bash
systemctl status memero-monitor | grep Memory
```

### Service-Uptime
```bash
systemctl status memero-monitor | grep Active
```

### Anzahl Neustarts (falls abgestürzt)
```bash
systemctl show memero-monitor -p NRestarts
```

### Alle fehlgeschlagenen Services
```bash
systemctl list-units --failed
```

---

## 🐛 Troubleshooting

### Service startet nicht

**Logs checken:**
```bash
sudo journalctl -u memero-monitor -n 50 --no-pager
```

**Häufige Fehler:**

1. **Python nicht gefunden**
   ```
   ExecStart=/root/memero/venv/bin/python3
   ```
   → Prüfe ob venv existiert: `ls /root/memero/venv/bin/python3`

2. **Permission denied**
   ```bash
   sudo chown -R root:root /root/memero
   sudo chmod +x /root/memero/monitoring/monitor.py
   ```

3. **Port 5000 bereits belegt**
   ```bash
   sudo netstat -tulpn | grep 5000
   # Prozess killen oder Port in config.py ändern
   ```

4. **.env Datei fehlt**
   ```bash
   ls /root/memero/.env
   # Falls nicht vorhanden:
   cp /root/memero/.env.example /root/memero/.env
   nano /root/memero/.env
   ```

---

### Service läuft, aber Dashboard nicht erreichbar

**Firewall prüfen:**
```bash
sudo ufw status
sudo ufw allow 5000/tcp
```

**Listening auf 0.0.0.0?**
```bash
sudo netstat -tulpn | grep 5000
```

Sollte zeigen:
```
tcp  0  0  0.0.0.0:5000  0.0.0.0:*  LISTEN
```

Falls `127.0.0.1:5000` → Ändere in `monitoring/config.py`:
```python
MONITOR_HOST = '0.0.0.0'
```

---

### Service startet nach Reboot nicht

**Auto-Start prüfen:**
```bash
sudo systemctl is-enabled memero-monitor
```

Sollte `enabled` zeigen. Falls nicht:
```bash
sudo systemctl enable memero-monitor
```

---

## 📚 Weitere Ressourcen

- **systemd Doku:** https://www.freedesktop.org/software/systemd/man/systemd.service.html
- **journalctl Guide:** https://www.digitalocean.com/community/tutorials/how-to-use-journalctl-to-view-and-manipulate-systemd-logs

---

## ✅ Checkliste nach Installation

- [ ] Service läuft: `sudo systemctl status memero-monitor`
- [ ] Dashboard erreichbar: `curl http://localhost:5000`
- [ ] Auto-Start aktiviert: `sudo systemctl is-enabled memero-monitor`
- [ ] Logs funktionieren: `sudo journalctl -u memero-monitor -n 10`
- [ ] SSH-Disconnect-Test bestanden
- [ ] Firewall konfiguriert: `sudo ufw allow 5000/tcp`

---

**🎉 Fertig! Dein Monitoring läuft jetzt 24/7!**
