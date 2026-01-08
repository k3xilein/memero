#!/bin/bash

###############################################################################
# MEMERO Monitoring - systemd Service Deinstallation
# Entfernt den systemd-Service komplett
###############################################################################

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║      MEMERO Monitoring - Service Deinstallation              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Root-Check
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}❌ Bitte als root ausführen: sudo ./uninstall_service.sh${NC}"
    exit 1
fi

# Service stoppen
echo -e "${YELLOW}⏹️  Stoppe Service...${NC}"
systemctl stop memero-monitor.service 2>/dev/null || true

# Service deaktivieren
echo -e "${YELLOW}🔧 Deaktiviere Auto-Start...${NC}"
systemctl disable memero-monitor.service 2>/dev/null || true

# Service-Datei löschen
echo -e "${YELLOW}🗑️  Lösche Service-Datei...${NC}"
rm -f /etc/systemd/system/memero-monitor.service

# systemd neu laden
echo -e "${YELLOW}🔄 Lade systemd neu...${NC}"
systemctl daemon-reload
systemctl reset-failed

echo ""
echo -e "${GREEN}✅ Service erfolgreich deinstalliert!${NC}"
echo ""
echo -e "${YELLOW}💡 Das Monitoring kann jetzt wieder manuell gestartet werden:${NC}"
echo -e "   cd /root/memero/monitoring"
echo -e "   python3 monitor.py"
echo ""
