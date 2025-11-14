#!/usr/bin/env bash

set -e

echo "🎧 Force A2DP Only — Bluetooth High Fidelity Audio Setup"

# --- Utility Functions --------------------------------------

backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "$file.bak_$(date +%Y%m%d_%H%M%S)"
        echo "  🔹 Backup created: $file"
    fi
}

ensure_dir() {
    local dir="$1"
    mkdir -p "$dir"
}

# --- Detect audio server ------------------------------------

AUDIO_SERVER=$(pactl info 2>/dev/null | grep "Server Name" | awk '{print $3}')

echo "🔍 Detected audio server: $AUDIO_SERVER"

# --- Disable HSP/HFP in PipeWire -----------------------------

if [[ "$AUDIO_SERVER" == "PipeWire" ]]; then
    echo "➡ Applying PipeWire configuration..."

    CONFIG_DIR="$HOME/.config/pipewire/media-session.d"
    ensure_dir "$CONFIG_DIR"

    CONFIG_FILE="$CONFIG_DIR/bluetooth-disable-hsp-hfp.conf"

    cat > "$CONFIG_FILE" <<EOF
{
  "bluez5.enable-hsp": false,
  "bluez5.enable-hfp": false
}
EOF

    echo "  ✔ Created: $CONFIG_FILE"
    echo "  ✔ HSP/HFP disabled for PipeWire"

    echo "🔄 Restarting PipeWire..."
    systemctl --user restart pipewire pipewire-pulse || true

# --- Disable HSP/HFP in PulseAudio ---------------------------

elif [[ "$AUDIO_SERVER" == "pulseaudio" ]]; then
    echo "➡ Applying PulseAudio configuration..."

    PA_FILE="/etc/pulse/default.pa"

    if [[ -f "$PA_FILE" ]]; then
        sudo bash -c "
            $(declare -f backup_file)
            backup_file \"$PA_FILE\"
        "

        # Only modify if not already set
        if ! grep -q "headset=none" "$PA_FILE"; then
            echo "  ✔ Updating $PA_FILE"

            sudo sed -i 's/load-module module-bluetooth-discover.*/load-module module-bluetooth-discover headset=none/' "$PA_FILE"

        else
            echo "  ✔ PulseAudio already configured for A2DP-only"
        fi
    else
        echo "  ⚠ PulseAudio config file not found. Skipping."
    fi

    echo "🔄 Restarting PulseAudio..."
    pulseaudio -k || true

else
    echo "⚠ Could not determine audio server. Skipping audio configuration."
fi

# --- BlueZ configuration (applies to all setups) -------------

echo "➡ Applying BlueZ configuration..."

BLUEZ_FILE="/etc/bluetooth/main.conf"

if [[ -f "$BLUEZ_FILE" ]]; then
    sudo bash -c "
        $(declare -f backup_file)
        backup_file \"$BLUEZ_FILE\"
    "
fi

# Append or update Handsfree=false
sudo sed -i '/^\[General\]/,/^\[/ {/Handsfree/d}' "$BLUEZ_FILE" 2>/dev/null || true

sudo sed -i '/^\[General\]/a Handsfree=false' "$BLUEZ_FILE" || {
    echo "[General]" | sudo tee -a "$BLUEZ_FILE" >/dev/null
    echo "Handsfree=false" | sudo tee -a "$BLUEZ_FILE" >/dev/null
}

echo "  ✔ BlueZ now prevents HFP/HSP at the Bluetooth stack level"

echo "🔄 Restarting Bluetooth..."
sudo systemctl restart bluetooth || true

# --- Final message -------------------------------------------

echo ""
echo "🎉 Done! Your machine will now ONLY connect using A2DP (High Fidelity)."
echo "No more hands-free profile, no more low-quality sound."
echo ""
echo "You may need to:"
echo "  • Reconnect your Bluetooth earbuds"
echo "  • Or reboot the system once"
echo ""
echo "Enjoy your clean A2DP-only audio! 🎶"
