# Enter the Wired

A universal bash-based installer for ACCELA with optional SLSsteam integration on Linux.

## What is ACCELA?

ACCELA is an open-source game client built with Python/.NET that provides various features for gaming on Linux. This installer sets up ACCELA with all required dependencies in an isolated Python virtual environment.

## What is SLSsteam?

SLSsteam is a Steam plugin that enables playing games not owned in your Steam library. It uses LD_AUDIT injection to patch Steam at runtime without modifying Steam files.

## Quick Install

```bash
curl -fsSL https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/enter-the-wired | sh
```

## Features

- **Cross-Distribution Support**
  - Fedora/RHEL/CentOS (dnf)
  - Debian/Ubuntu (apt)
  - Arch Linux (pacman)
  - Bazzite / SteamOS support

- **Automatic Dependency Installation**
  - Python 3.x + pip
  - SDL2 libraries (devel, mixer, image, ttf)
  - GCC/G++ compiler
  - Git
  - libnotify
  - .NET SDK 9.0
  - p7zip

- **ACCELA Setup**
  - Downloads pre-compiled source from catbox.moe
  - Creates isolated Python virtual environment
  - Installs all Python dependencies
  - Configures pygame compatibility

- **SLSsteam Integration (LD_AUDIT Injection)**
  - Installs latest release from GitHub
  - **Gaming Mode**: Uses systemd drop-in (`LD_AUDIT` environment variable)
  - **Desktop Mode** (Bazzite): Creates wrapper script and patches desktop shortcuts
  - Automatic backup with timestamp
  - SafeMode enabled by default
  - Configuration via `~/.config/SLSsteam/config.yaml`

## Requirements

- Linux with a supported distribution
- curl or wget
- sudo access
- For SLSsteam: Steam installed at `$HOME/.steam/steam`

## Installation Locations

```
ACCELA:        ~/.local/share/ACCELA/
SLSsteam:      ~/.local/share/SLSsteam/
SLSsteam cfg:  ~/.config/SLSsteam/
Systemd drop:  ~/.config/systemd/user/gamescope-session*.d/slssteam.conf
```

## Manual Installation

```bash
curl -fsSL https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/enter-the-wired -o enter-the-wired
chmod +x enter-the-wired
./enter-the-wired
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/ciscosweater/enter-the-wired/main/uninstall | sh
```

The uninstall script will:
- Remove LD_AUDIT systemd drop-in
- Clean up Desktop Mode wrapper and shortcuts
- Remove ACCELA directory
- Remove SLSsteam directories
- Restore any backups

## Troubleshooting

### Steam is running during SLSsteam installation
The installer will warn you to close Steam before proceeding with SLSsteam installation.

### .NET SDK installation fails
The script uses Microsoft's official installation script. If it fails, ensure you have an internet connection and try running the installer again.

### ACCELA fails to start
Check that the virtual environment was created correctly:
```bash
source ~/.local/share/ACCELA/.venv/bin/activate
python -c "import accela"
```

### SLSsteam not working on SteamOS/Bazzite
- Ensure you rebooted after installation (systemd needs reload)
- Check the injector status in systemd:
```bash
systemctl --user status gamescope-session.service
```

## How it Works

1. **Distribution Detection**: Reads `/etc/os-release` to identify the package manager
2. **Dependency Installation**: Installs all required system packages
3. **ACCELA Setup**: Downloads and extracts ACCELA, then sets up the Python venv
4. **SLSsteam**: Fetches latest release from GitHub, configures LD_AUDIT injection
   - **Gaming Mode**: Creates systemd drop-in for `gamescope-session.service`
   - **Desktop Mode**: Creates wrapper script and patches desktop entries (Bazzite only)

## Credits

- **nukhes** (Discord) - Original idea and concept
- **ciscosweater** - Main maintainer
- **JD Ros** (YouTube) - LD_AUDIT systemd drop-in integration
- SLSsteam by AceSLS

## License

This installer is provided as-is.

## Repository

[https://github.com/ciscosweater/enter-the-wired](https://github.com/ciscosweater/enter-the-wired)
