# Ubuntu Developer Setup

A comprehensive, automated setup script for configuring a fresh Ubuntu installation with all the essential development tools, applications, and configurations needed for a productive development environment.

## 📑 Table of Contents

- [Overview](#-overview)
- [Key Features](#-key-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Structure](#-structure)
- [Detailed Setup Steps](#-detailed-setup-steps)
  - [Section A: Core System Setup](#section-a-core-system-setup)
  - [Section B: Development Tools](#section-b-development-tools)
  - [Section C: Productivity Tools](#section-c-productivity-tools)
  - [Section D: System Configuration](#section-d-system-configuration)
  - [Section E: BBB Job Setup (Optional)](#section-e-bbb-job-setup-optional)
- [Configuration Options](#-configuration-options)
  - [User Information](#user-information)
  - [Installation Toggles](#installation-toggles)
  - [GNOME Settings](#gnome-settings)
- [Customization](#-customization)
  - [Adding Your Own Aliases](#adding-your-own-aliases)
  - [Modifying GNOME Settings](#modifying-gnome-settings)
  - [Adding New Software](#adding-new-software)
- [Logging](#-logging)
- [Troubleshooting](#-troubleshooting)
  - [Script fails with permission error](#script-fails-with-permission-error)
  - [Package installation fails](#package-installation-fails)
  - [Docker group not working](#docker-group-not-working)
  - [NVM command not found](#nvm-command-not-found)
  - [Re-running the script](#re-running-the-script)
- [Contributing](#-contributing)
- [License](#-license)
- [Author](#-author)
- [Acknowledgments](#-acknowledgments)

## 🎯 Overview

This setup system automates the installation and configuration of:

- **Core Development Tools**: Git, GitHub CLI, NVM/Node.js, Docker, VSCode
- **Web Browsers**: Google Chrome
- **Communication**: Slack, Discord
- **Productivity**: Obsidian, Peek, VLC, Flameshot
- **Terminal**: ZSH with Oh My Zsh, Terminator, and custom aliases
- **System Configuration**: GNOME settings, firewall, Bluetooth fixes, locale settings
- **Optional BBB Setup**: BigBlueButton development environment configuration

## ✨ Key Features

- ✅ **Idempotent**: Safe to run multiple times - won't break existing installations
- 📝 **Comprehensive Logging**: All operations logged to `~/ubuntu-setup.log`
- ⚙️ **Configurable**: YAML-based configuration file for easy customization
- 🔍 **Smart Installation**: Checks if packages are already installed before proceeding
- 🔐 **Safe Backups**: Automatically backs up existing configuration files
- 📊 **Interactive**: Asks for confirmation before overwriting configs
- 🎨 **Modular**: Organized into separate scripts by functionality
- 📦 **LTS Versions**: Always installs Long Term Support versions where applicable

## 📋 Prerequisites

- Fresh Ubuntu installation (tested on Ubuntu 22.04 LTS and 24.04 LTS)
- User account with sudo privileges
- Internet connection
- At least 10GB of free disk space
- **Git** installed (required if cloning the repository)

## 🚀 Quick Start

### 1. Clone or Download This Repository

```bash
cd ~
git clone https://github.com/antonbsa/ubuntu-setup.git
cd ubuntu-setup
```

### 2. Configure Your Setup

Copy the template configuration file and customize it:

```bash
cp config.template.yaml config.yaml
nano config.yaml  # or use your preferred editor
```

Edit `config.yaml` to specify:
- Your name and GitHub email
- Which tools to install
- Your preferred settings

### 3. Make the Script Executable

```bash
chmod +x main.sh
```

### 4. Run the Setup

```bash
./main.sh
```

The script will:
1. Perform pre-flight checks
2. Display a configuration summary
3. Ask for confirmation
4. Install and configure everything
5. Display a summary of apps requiring manual login

### 5. Post-Installation

After the script completes:

1. **Log out and log back in** (required for Docker group and ZSH shell changes)
2. Sign in to applications that require authentication:
   - GitHub CLI: `gh auth login`
   - Visual Studio Code (sync settings)
   - Google Chrome (sync bookmarks)
   - Slack
   - Discord
3. **Bluetooth headphones** will automatically use A2DP (high-quality) profile if setup was confirmed during installation

## 🔧 Customization

### Adding Your Own Aliases

Edit `config/zsh-aliases.sh` to add your custom shell aliases and functions.

### Modifying GNOME Settings

Edit `scripts/04-system-config.sh` in the `configure_gnome()` function.

### Adding New Software

1. Add installation function to appropriate script in `scripts/`
2. Add configuration option to `config.template.yaml`
3. Call the function from the script's main function

## 📝 Logging

All operations are logged to `~/ubuntu-setup.log` with timestamps:

```bash
# View the log
cat ~/ubuntu-setup.log

# Follow the log in real-time
tail -f ~/ubuntu-setup.log
```

Log levels:
- `[INFO]` - General information
- `[SUCCESS]` - Successful operation
- `[WARNING]` - Non-critical issues
- `[ERROR]` - Errors that occurred

## 🐛 Troubleshooting

### Script fails with permission error
Make sure you have sudo privileges and the script is executable:
```bash
chmod +x main.sh
```

### Package installation fails
Check your internet connection and try running:
```bash
sudo apt update
```

### Docker group not working
Log out and log back in for group changes to take effect.

### NVM command not found
NVM is loaded in new shell sessions. Either:
- Start a new terminal session, or
- Run: `source ~/.nvm/nvm.sh`

### Re-running the script
The script is idempotent and safe to run multiple times. It will:
- Skip already installed packages
- Ask before overwriting configs
- Continue from where it left off if interrupted

## 📄 License

This project is open source and available under the MIT License.

## 🙏 Acknowledgments

- Built for Ubuntu-based systems
- Inspired by the need for reproducible development environments
- Designed for BigBlueButton development workflows

---

**Note**: This setup is opinionated and based on personal preferences. Review and customize the configuration file before running to match your specific needs.
