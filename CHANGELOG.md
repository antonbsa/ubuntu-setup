# Changelog

All notable changes and features of the Ubuntu Setup system.

## Version 1.0.0 - Initial Release

### 📦 Complete Setup System

A fully automated Ubuntu setup system with modular scripts, comprehensive configuration, and detailed logging.

### ✨ Features

#### Core Functionality
- **Idempotent execution**: Safe to run multiple times without breaking existing installations
- **Comprehensive logging**: All operations logged to `~/ubuntu-setup.log` with timestamps
- **YAML-based configuration**: Easy customization via `config.yaml`
- **Smart package detection**: Checks if packages are already installed before proceeding
- **Automatic backups**: Backs up existing configuration files before overwriting
- **Interactive confirmations**: Asks before overwriting important files
- **Modular architecture**: Separate scripts for different installation categories
- **LTS version preference**: Always installs Long Term Support versions

#### Installation Categories

**Section A: Core System Setup**
- System updates and upgrades
- Essential build tools (build-essential, curl, wget, etc.)
- Package cleanup and maintenance

**Section B: Development Tools**
- NVM (Node Version Manager) with Node.js LTS
- GitHub CLI with authentication setup
- Visual Studio Code
- Docker with all plugins and group configuration
- Google Chrome
- Insomnia (API client)
- Terminator terminal emulator with custom configuration
- ZSH with Oh My Zsh framework
- Flameshot with custom keyboard shortcuts
- SSH key generation (ed25519 by default)
- NPM global packages: TypeScript, Playwright (with browsers)

**Section C: Productivity Tools**
- Obsidian with optional vault cloning
- Peek screen recorder
- VLC Media Player
- Terminal utilities: bat, htop, tmux, curl, wget, jq
- Slack
- Discord
- Workspace folder structure (`~/www/hub`, `~/www/personal`)

**Section D: System Configuration**
- Bluetooth A2DP fix for headphones
- UFW firewall configuration
- Locale and UTF-8 fixes
- Timezone configuration
- GNOME settings:
  - Dark mode
  - Performance power mode
  - Dock customization (icon size 30px)
  - Auto-suspend (100 minutes)
  - Night light (17:30-08:00, 33% warmth)
- ZSH aliases integration
- Git global configuration

**Section E: BBB Job Setup (Optional)**
- BBB-specific ZSH aliases
- BBB docker setup script
- `~/www/bbb/shared` folder creation
- BBB Docker Dev repository cloning
- Version detection and selection
- Version-specific container creation scripts (`create_bbb30.sh`, `create_bbb31.sh`)
- Terminator layout for BBB development

### 📁 File Structure

```
ubuntu-setup/
├── main.sh                          # Main orchestrator (executable)
├── config.yaml                      # User configuration
├── config.template.yaml             # Configuration template
├── README.md                        # Comprehensive documentation
├── QUICKSTART.md                    # Quick reference guide
├── CHANGELOG.md                     # This file
├── prompt.md                        # Development notes
├── scripts/                         # Installation scripts
│   ├── utils.sh                     # Utility functions
│   ├── 01-core-system.sh           # Core system setup
│   ├── 02-dev-tools.sh             # Development tools
│   ├── 03-productivity-tools.sh    # Productivity apps
│   ├── 04-system-config.sh         # System configuration
│   └── 05-bbb-setup.sh             # BBB setup
├── config/                          # Configuration files
│   ├── base-terminator-settings.txt # Terminator config
│   ├── setup-a2dp-fix.sh           # Bluetooth A2DP auto-switch setup
│   └── zsh-aliases.sh              # General ZSH aliases
└── bbb/                            # BBB-specific files
    ├── aliases.sh                   # BBB aliases
    ├── terminator-settings.txt      # BBB Terminator layout
    └── docker/
        ├── additional-container-setup.txt
        └── bbb-setup.sh
```

### 🎯 Configuration Options

All options available in `config.template.yaml`:

- **User Information**: Name, GitHub email, username, SSH key settings
- **System Localization**: Timezone, locale, keyboard layout
- **Installation Toggles**: Enable/disable any component
- **Browser Choices**: Chrome, Chromium
- **Editor Choices**: VSCode, Vim, Zed
- **Development Tools**: Docker, Node.js, Python, Java
- **Communication Apps**: Slack, Discord
- **Productivity Apps**: Obsidian, Peek, VLC, Spotify
- **Terminal Tools**: bat, htop, tmux, jq
- **Git Configuration**: Default branch, GPG signing, editor
- **GNOME Settings**: Theme, power mode, dock, night light, favorites
- **BBB Setup**: Repository, versions, container settings

### 🛠️ Utility Functions

Available in `scripts/utils.sh`:

**Logging**
- `log_info()` - Information messages
- `log_success()` - Success messages
- `log_warning()` - Warning messages
- `log_error()` - Error messages
- `log_section()` - Section headers

**User Interaction**
- `ask_confirmation()` - Interactive yes/no prompts
- `add_requires_interaction()` - Track apps needing manual login
- `print_interaction_summary()` - Display summary at end

**Package Management**
- `is_installed()` - Check if package/command exists
- `check_and_log_installed()` - Check and log if already installed

**Configuration**
- `get_config_value()` - Read values from YAML config
- `check_config_enabled()` - Check if option is enabled

**File Management**
- `backup_file()` - Create timestamped backup
- `handle_error()` - Error handling with logging

### 📋 Post-Installation Actions

The system tracks and displays applications requiring manual interaction:

1. **GitHub CLI**: `gh auth login`
2. **Visual Studio Code**: Sign in for Settings Sync
3. **Google Chrome**: Sign in to sync bookmarks
5. **Slack**: Sign in to workspace
6. **Discord**: Sign in to account
7. **SSH Key**: Add public key to GitHub/GitLab
8. **Bluetooth**: A2DP auto-switch service installed (if confirmed during setup)

### 🔒 Security Features

- UFW firewall enabled by default
- Secure SSH key generation (ed25519)
- Automatic backup of existing configurations
- Confirmation prompts for destructive operations

### 📝 Documentation

- **README.md**: Comprehensive guide with detailed explanations
- **QUICKSTART.md**: Quick reference for common tasks
- **CHANGELOG.md**: Version history and features
- **Inline comments**: Extensive documentation in all scripts
- **config.template.yaml**: Detailed comments for all options

### 🎨 Customization

Easy to extend:
- Add new software installations
- Modify GNOME settings
- Add custom aliases
- Configure additional tools
- Adjust version preferences

### ✅ Tested On

- Ubuntu 22.04 LTS (Jammy Jellyfish)
- Ubuntu 24.04 LTS (Noble Numbat)

### 🚀 Performance

- Parallel execution where safe
- Smart package caching
- Minimal re-downloads on re-runs
- Efficient error recovery

### 📊 Logging

Complete installation log includes:
- Timestamp for every operation
- Success/warning/error indicators
- Full command outputs
- Summary of installed components
- List of apps requiring user interaction

### 🎁 Extras

- Custom Git aliases for productivity
- BBB-specific development workflow
- Terminator layouts for different projects
- Flameshot keyboard shortcuts
- Bluetooth audio quality fixes

---

## Future Enhancements (Potential)

- [ ] Support for other Ubuntu-based distributions
- [ ] GUI configuration tool
- [ ] Plugin system for custom installations
- [ ] Docker-based installation for isolation
- [ ] Rollback functionality
- [ ] Update checker for installed packages
- [ ] Config validation before execution
- [ ] Parallel script execution where safe
- [ ] Installation progress bar
- [ ] Email notification on completion

---

**Author**: Anton B  
**GitHub**: [@antonbsa](https://github.com/antonbsa)  
**License**: MIT
