#!/bin/bash
set -e

echo "[A2DP FIX] Installing required packages..."
sudo apt update -y
sudo apt install -y pulseaudio-utils bluez

echo "[A2DP FIX] Creating auto-switch service..."

SERVICE_FILE="/etc/systemd/system/a2dp-autoswitch.service"
SCRIPT_FILE="/usr/local/bin/a2dp-autoswitch.sh"

sudo tee "$SCRIPT_FILE" > /dev/null <<'EOF'
#!/bin/bash

DEVICE_MAC=$(bluetoothctl info | grep "Device" | awk '{print $2}')

if [ -n "$DEVICE_MAC" ]; then
    bluetoothctl connect "$DEVICE_MAC"
    sleep 2
    pactl set-card-profile bluez_card."$DEVICE_MAC" a2dp-sink
fi
EOF

sudo chmod +x "$SCRIPT_FILE"

sudo tee "$SERVICE_FILE" > /dev/null <<EOF
[Unit]
Description=Force A2DP on Bluetooth connect
After=bluetooth.service pulseaudio.service

[Service]
Type=oneshot
ExecStart=$SCRIPT_FILE

[Install]
WantedBy=default.target
EOF

echo "[A2DP FIX] Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable a2dp-autoswitch.service

echo "[A2DP FIX] Running once now..."
sudo systemctl start a2dp-autoswitch.service

echo "[A2DP FIX] Done."
