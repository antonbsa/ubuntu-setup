#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

cleanup() {
    rm -rf "${TMP_DIR:-}"

    if [[ -n "${CONFIG_BACKUP:-}" && -f "${CONFIG_BACKUP:-}" ]]; then
        mv "$CONFIG_BACKUP" config.yaml
    elif [[ -f config.yaml && "${CREATED_CONFIG:-0}" == "1" ]]; then
        rm -f config.yaml
    fi
}

trap cleanup EXIT

TMP_DIR=$(mktemp -d)
CONFIG_BACKUP=""
CREATED_CONFIG=0

if [[ -f config.yaml ]]; then
    CONFIG_BACKUP="$TMP_DIR/config.yaml.backup"
    cp config.yaml "$CONFIG_BACKUP"
else
    cp config.template.yaml config.yaml
    CREATED_CONFIG=1
fi

cat > "$TMP_DIR/yq" <<'YQEOF'
#!/bin/bash

if [[ "$1" != "eval" ]]; then
    exit 1
fi

case "$2" in
    .installation.common_packages) echo true ;;
    .installation.nodejs) echo true ;;
    .installation.docker) echo true ;;
    .installation.editors.vscode) echo true ;;
    .installation.browsers.google_chrome) echo true ;;
    .installation.terminals.terminator) echo true ;;
    .installation.peek) echo true ;;
    .installation.insomnia) echo true ;;
    .installation.flameshot) echo true ;;
    .installation.terminal_tools.bat) echo true ;;
    .installation.terminal_tools.htop) echo true ;;
    .installation.terminal_tools.tmux) echo false ;;
    .installation.terminal_tools.jq) echo true ;;
    .installation.npm_packages.typescript) echo true ;;
    .installation.npm_packages.playwright) echo false ;;
    .installation.slack) echo true ;;
    .installation.discord) echo true ;;
    .installation.obsidian) echo true ;;
    .installation.vlc) echo true ;;
    .gnome.configure) echo true ;;
    .git.setup) echo true ;;
    .workspace.zsh.install_oh_my_zsh) echo true ;;
    .workspace.zsh.set_as_default_shell) echo true ;;
    .bbb.enabled) echo false ;;
    .gnome.settings.dark_mode) echo true ;;
    .gnome.settings.dock_icon_size) echo 30 ;;
    .gnome.settings.night_light.enabled) echo true ;;
    .gnome.settings.night_light.schedule_from) echo 17.5 ;;
    .gnome.settings.night_light.schedule_to) echo 8.0 ;;
    .gnome.settings.night_light.temperature) echo 3700 ;;
    *) echo false ;;
esac
YQEOF
chmod +x "$TMP_DIR/yq"

export PATH="$TMP_DIR:$PATH"

echo "[1/4] Syntax validation"
bash -n main.sh
bash -n scripts/*.sh
bash -n config/setup-a2dp-fix.sh
bash -n bbb/docker/bbb-setup.sh

echo "[2/4] Referenced file checks"
for path in \
    config/zsh_aliases.sh \
    config/zshrc.sh \
    config/zshrc-before-source.sh \
    config/base-terminator-settings.txt \
    bbb/aliases.sh \
    bbb/terminator-settings.txt \
    bbb/docker/bbb-setup.sh \
    bbb/docker/additional-container-setup.txt; do
    [[ -f "$path" ]] || {
        echo "Missing required file: $path" >&2
        exit 1
    }
done

echo "[3/4] Config resolution checks"
bash -c '
    source scripts/utils.sh

    [[ "$(get_config_value ".installation.nodejs" config.template.yaml)" == "true" ]]
    [[ "$(get_config_value ".workspace.zsh.install_oh_my_zsh" config.template.yaml)" == "true" ]]
    [[ "$(get_config_value ".installation.terminal_tools.tmux" config.template.yaml)" == "false" ]]

    check_config_enabled ".installation.flameshot" config.template.yaml
    ! check_config_enabled ".bbb.enabled" config.template.yaml
'

echo "[4/4] Dry-run smoke test"
DRY_RUN_OUTPUT=$(XDG_CURRENT_DESKTOP=KDE ./main.sh --dry-run)
printf '%s\n' "$DRY_RUN_OUTPUT" | grep -q "DRY RUN MODE"
printf '%s\n' "$DRY_RUN_OUTPUT" | grep -q "Would run Section A: Core System Setup"
printf '%s\n' "$DRY_RUN_OUTPUT" | grep -q "No changes were applied"

echo "All validation checks passed"
