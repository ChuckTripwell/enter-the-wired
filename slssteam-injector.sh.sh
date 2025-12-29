#!/usr/bin/env bash
set -euo pipefail

# slssteam-injector.sh
# Dynamic installer for LD_AUDIT drop-in
# Auto-detects Bazzite vs SteamOS, scans for .so files, and enforces SafeMode

# --- OS DETECTION ---
if grep -qi "bazzite" /etc/os-release; then
    SERVICE_NAME="gamescope-session-plus@steam.service"
    log_os="Bazzite Detected"
elif grep -qi "steamos" /etc/os-release; then
    SERVICE_NAME="gamescope-session.service"
    log_os="SteamOS Detected"
else
    printf 'ERROR: This script currently only supports Bazzite and SteamOS.\n' >&2
    exit 1
fi

SERVICE_DIR="$HOME/.config/systemd/user/${SERVICE_NAME}.d"
DROPIN_FILE="$SERVICE_DIR/slssteam.conf"
BACKUP_DIR="$SERVICE_DIR/backups"
SLS_DIR="$HOME/.local/share/SLSsteam"
CONFIG_FILE="$HOME/.config/SLSsteam/config.yaml"

log() { printf '%s\n' "$*"; }
err() { printf 'ERROR: %s\n' "$*" >&2; }
timestamp() { date +"%Y%m%dT%H%M%S"; }

ensure_systemd_user() {
  if ! command -v systemctl >/dev/null 2>&1; then
    err "systemctl not found."
    exit 2
  fi
}

mk_backup_if_exists() {
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$DROPIN_FILE" ]]; then
    local b="$BACKUP_DIR/$(basename "$DROPIN_FILE").bak.$(timestamp)"
    mv -f "$DROPIN_FILE" "$b"
    log "Backed up existing drop-in to: $b"
  fi
}

configure_safemode() {
  if [[ -f "$CONFIG_FILE" ]]; then
    # Force SafeMode: yes in the config file
    sed -i 's/^SafeMode:.*/SafeMode: yes/' "$CONFIG_FILE"
    log "SafeMode has been enabled in config.yaml."
  else
    log "Warning: config.yaml not found at $CONFIG_FILE. Skipping SafeMode check."
  fi
}

install_action() {
  ensure_systemd_user
  log "$log_os"
  
  # --- DYNAMIC .SO DETECTION ---
  if [[ ! -d "$SLS_DIR" ]]; then
    err "SLSsteam directory not found at: $SLS_DIR"
    exit 1
  fi

  # Find all .so files
  local detected_files
  detected_files=$(find "$SLS_DIR" -maxdepth 1 -name "*.so" | sort)
  
  if [[ -z "$detected_files" ]]; then
    err "No .so files found in $SLS_DIR. Cannot install."
    exit 1
  fi

  # Build the LD_AUDIT string
  local audit_str=""
  while IFS= read -r file; do
    log "Found library: $file"
    local portable_path="${file/"$HOME"/%h}"
    if [[ -z "$audit_str" ]]; then
      audit_str="$portable_path"
    else
      audit_str="$audit_str:$portable_path"
    fi
  done <<< "$detected_files"

  # --- CONFIG TWEAKS ---
  configure_safemode

  # Prepare temp file
  local tmp
  tmp="$(mktemp)"
  cat >"$tmp" <<EOF
[Service]
Environment="LD_AUDIT=${audit_str}"
EOF
  chmod 644 "$tmp"

  # Check if identical
  if [[ -f "$DROPIN_FILE" ]]; then
    if cmp -s "$tmp" "$DROPIN_FILE"; then
      log "Systemd configuration matches current files. No drop-in changes needed."
      rm -f "$tmp"
      return 0
    else
      log "File list changed or new install. Updating configuration..."
      mk_backup_if_exists
    fi
  fi

  mkdir -p "$SERVICE_DIR"
  mv -f "$tmp" "$DROPIN_FILE"
  log "Wrote drop-in with new file list."

  systemctl --user daemon-reload
  log "Install complete. Return to Gaming Mode to play."
}

uninstall_action() {
  ensure_systemd_user
  log "$log_os"

  # We purposefully DO NOT revert SafeMode here.
  
  if [[ ! -f "$DROPIN_FILE" ]]; then
    log "No drop-in active. Nothing to uninstall."
    return 0
  fi

  mkdir -p "$BACKUP_DIR"
  local saved="$BACKUP_DIR/$(basename "$DROPIN_FILE").removed.$(timestamp)"
  mv -f "$DROPIN_FILE" "$saved"
  log "Uninstalled drop-in. Backup saved to: $saved"

  systemctl --user daemon-reload
  log "Uninstall complete. Return to Gaming Mode to apply."
}

status_action() {
  log "OS: $log_os"
  log "Service Target: $SERVICE_NAME"
  log "Drop-in location: $DROPIN_FILE"
  
  if [[ -f "$DROPIN_FILE" ]]; then
    log "Status: FILE PRESENT"
    printf 'Contents:\n--------------------------------\n'
    sed -n '1,200p' "$DROPIN_FILE" || true
    printf '--------------------------------\n'
  else
    log "Status: FILE MISSING (Not Installed)"
  fi
  
  log ""
  log "SafeMode Status in config.yaml:"
  if [[ -f "$CONFIG_FILE" ]]; then
    grep "^SafeMode:" "$CONFIG_FILE" || log "  (SafeMode key not found)"
  else
    log "  (Config file missing)"
  fi

  log ""
  log "Checking if Service '$SERVICE_NAME' sees LD_AUDIT:"
  # This checks the specific service environment, not global environment
  if systemctl --user show "$SERVICE_NAME" --property=Environment | grep -q "LD_AUDIT"; then
     log "  [OK] Systemd has loaded LD_AUDIT for this service."
     systemctl --user show "$SERVICE_NAME" --property=Environment | grep "LD_AUDIT"
  else
     log "  [Inactive] LD_AUDIT is NOT loaded in the service environment."
  fi

  log ""
  log "Scanning $SLS_DIR for .so files:"
  if [[ -d "$SLS_DIR" ]]; then
    ls -1 "$SLS_DIR"/*.so 2>/dev/null || log "  (none found)"
  else
    log "  (Directory missing)"
  fi
}

print_usage_and_exit() {
  printf '%s\n' "Usage: $0 {install|uninstall|status}"
  exit 1
}

if [[ $# -lt 1 ]]; then
  print_usage_and_exit
fi

case "$1" in
  install)   install_action ;;
  uninstall) uninstall_action ;;
  status)    status_action ;;
  *) print_usage_and_exit ;;
esac

exit 0