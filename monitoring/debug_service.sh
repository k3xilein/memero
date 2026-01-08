#!/bin/bash

# MEMERO Service Debug Script
# Zeigt detaillierte Fehlerinfos wenn Service nicht startet

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║            MEMERO Service Fehlerdiagnose                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. Service Status
echo "1️⃣  Service Status:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
systemctl status memero-monitor --no-pager -l | head -20
echo ""

# 2. Journal Logs (letzte 30 Zeilen)
echo "2️⃣  System Journal (letzte Fehler):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
journalctl -u memero-monitor -n 30 --no-pager
echo ""

# 3. Monitor.log
echo "3️⃣  Monitor Log-Datei:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /root/memero/monitoring/monitor.log ]; then
    echo "Letzte 30 Zeilen aus monitor.log:"
    tail -30 /root/memero/monitoring/monitor.log
else
    echo "⚠️  monitor.log existiert noch nicht"
fi
echo ""

# 4. Python & Dependencies
echo "4️⃣  Python Environment:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
/root/memero/venv/bin/python3 --version
echo ""
echo "Installierte Packages:"
/root/memero/venv/bin/pip list | grep -E "Flask|Werkzeug|psutil|dotenv"
echo ""

# 5. Import-Test
echo "5️⃣  Python Import-Test:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /root/memero
/root/memero/venv/bin/python3 << 'PYEOF'
import sys
sys.path.insert(0, '/root/memero')

print("Testing imports...")

# Test 1: dotenv
try:
    from dotenv import load_dotenv
    print("✓ python-dotenv OK")
except ImportError as e:
    print(f"✗ python-dotenv FEHLT: {e}")

# Test 2: Flask
try:
    from flask import Flask
    print("✓ Flask OK")
except ImportError as e:
    print(f"✗ Flask FEHLT: {e}")

# Test 3: psutil
try:
    import psutil
    print("✓ psutil OK")
except ImportError as e:
    print(f"✗ psutil FEHLT: {e}")

# Test 4: monitoring.config
try:
    from monitoring.config import MONITOR_HOST, MONITOR_PORT, WALLET_PUBLIC_KEY
    print(f"✓ monitoring.config OK")
    print(f"  → Host: {MONITOR_HOST}")
    print(f"  → Port: {MONITOR_PORT}")
    if WALLET_PUBLIC_KEY:
        print(f"  → Wallet: {WALLET_PUBLIC_KEY[:8]}...{WALLET_PUBLIC_KEY[-8:]}")
    else:
        print(f"  ⚠️  WALLET_PUBLIC_KEY ist leer!")
except Exception as e:
    print(f"✗ monitoring.config FEHLER: {e}")
    import traceback
    traceback.print_exc()

# Test 5: monitor.py direkt
try:
    from monitoring import monitor
    print("✓ monitoring.monitor OK")
except Exception as e:
    print(f"✗ monitoring.monitor FEHLER: {e}")
    import traceback
    traceback.print_exc()
PYEOF
echo ""

# 6. .env Check
echo "6️⃣  Environment-Variablen (.env):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /root/memero/.env ]; then
    echo "✓ .env existiert"
    echo ""
    echo "Monitoring-relevante Variablen:"
    grep -E "WALLET_PUBLIC_KEY|MONITOR" /root/memero/.env || echo "  (keine gefunden)"
else
    echo "✗ .env FEHLT!"
    echo ""
    echo "Bitte erstellen:"
    echo "  cp /root/memero/.env.example /root/memero/.env"
    echo "  nano /root/memero/.env"
fi
echo ""

# 7. Service-Datei prüfen
echo "7️⃣  Service-Konfiguration:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f /etc/systemd/system/memero-monitor.service ]; then
    cat /etc/systemd/system/memero-monitor.service
else
    echo "✗ Service-Datei nicht gefunden!"
fi
echo ""

# 8. Manueller Start-Test
echo "8️⃣  Manueller Start-Test:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Versuche monitor.py manuell zu starten (Strg+C zum Abbrechen):"
echo ""
echo "Befehl: cd /root/memero && /root/memero/venv/bin/python3 /root/memero/monitoring/monitor.py"
echo ""
echo "Führe aus? (y/n)"
read -r -n 1 response
echo ""
if [[ "$response" =~ ^[Yy]$ ]]; then
    cd /root/memero
    timeout 5 /root/memero/venv/bin/python3 /root/memero/monitoring/monitor.py || echo "Exit Code: $?"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                     Diagnose abgeschlossen                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "💡 Häufigste Probleme:"
echo "   1. python-dotenv fehlt → pip install python-dotenv"
echo "   2. .env fehlt → cp .env.example .env && nano .env"
echo "   3. Flask fehlt → pip install -r requirements.txt"
echo "   4. Pfad falsch in Service-Datei"
echo ""
echo "🔧 Nach Fixes:"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl restart memero-monitor"
echo "   sudo systemctl status memero-monitor"
echo ""
