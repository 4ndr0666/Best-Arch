#!/bin/bash

# --- // Auto-escalate:
if [ "$(id -u)" -ne 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# --- // Banner:
echo -e "\033[34m"
cat << "EOF"
__________                __                                     _____.__                         .__
\______   \_____    ____ |  | ____ ________   ____  ____   _____/ ____\__| ____  ______      _____|  |__
 |    |  _/\__  \ _/ ___\|  |/ /  |  \____ \_/ ___\/  _ \ /    \   __\|  |/ ___\/  ___/     /  ___/  |  \
 |    |   \ / __ \\  \___|    <|  |  /  |_> >  \__(  <_> )   |  \  |  |  / /_/  >___ \      \___ \|   Y  \
 |______  /(____  /\___  >__|_ \____/|   __/ \___  >____/|___|  /__|  |__\___  /____  > /\ /____  >___|  /
        \/      \/     \/     \/     |__|        \/           \/        /_____/     \/  \/      \/     \/
EOF
echo -e "\033[0m"

# --- // Initialize variables:
backup_dir="${PWD}/Backupconfigs"
base_name="config-backup-$(date +'%Y%m%d%H%M%S')"
log_file="${backup_dir}/backup.log"
checksum_file="${backup_dir}/${base_name}/checksum.md5"
handle_error() {
  if [ $? -ne 0 ]; then
    echo "Error encountered. Check ${log_file} for details."
    exit 1
  fi
}

confirm_action() {
  read -p "$1 [y/n]: " choice
  [[ "$choice" == "y" || "$choice" == "Y" ]]
}

# --- // Create backup dir and log file:
mkdir -p "${backup_dir}"
echo "Backup Log - $(date)" > "${log_file}"


display_menu() {
    printf "# --- // Methods //\n\
    1. User config files only\n\
    2: Entire /etc directory\n\
    3: Custom selection via fzf\n\
    4: 1 & 2\n\
Enter method: "
}
display_menu

read -r method

case "$method" in
  1)
    # Initialize array with default backup paths
    declare -a paths=(
      "/home/${USER}/.config"
      "/home/${USER}/.local"
      "/home/${USER}/.oh-my-zsh"
      "/home/${USER}/.bash_profile"
      "/home/${USER}/.zshrc"
      "/home/${USER}/.bashrc"
    )
    ;;
  2)
    # Comprehensive backup of entire /etc directory
    paths=("/etc")
    ;;
  3)
    # Interactive mode using fzf
    custom_paths=$(find / -type f | fzf -m)
    paths=($custom_paths)
    ;;
  4)
    declare -a paths=(
      "/home/${USER}/.config"
      "/home/${USER}/.local"
      "/home/${USER}/.oh-my-zsh"
      "/home/${USER}/.bash_profile"
      "/home/${USER}/.zshrc"
      "/home/${USER}/.bashrc"
      "/etc/"
    )
    ;;
  *)
    echo "Invalid choice."
    exit 1
    ;;
esac

# Create a new directory for this backup
mkdir -p "${backup_dir}/${base_name}"

# Loop through each path and back them up
for path in "${paths[@]}"; do
  if [ -e "$path" ]; then
    echo "Backing up ${path}..." >> "${log_file}"
    cp -r "${path}" "${backup_dir}/${base_name}/" >> "${log_file}" 2>&1
    handle_error
    echo "Backup for ${path} completed." >> "${log_file}"
  else
    echo "Path ${path} does not exist, skipping..." >> "${log_file}"
  fi
done

# Create checksum file for integrity verification
find "${backup_dir}/${base_name}/" -type f -exec md5sum {} \\; > "${checksum_file}"
handle_error

# Implement Retention Policy: Keep last 5 backups and delete the rest
ls -tp "${backup_dir}/" | grep '/$' | tail -n +6 | xargs -I {} rm -r -- "${backup_dir}/{}"

echo "Backup completed successfully. Check ${log_file} for details."

if confirm_action "View the logfile?"; then
    less "${log_file}"
fi

# Interactive backup section
if [ "$method" -eq 3 ]; then
  if confirm_action "Would you like to save this configuration for future use?"; then
    echo "# User-added backup paths" >> "$0"
    for path in $custom_paths; do
      echo "paths+=(\"$path\")" >> "$0"
    done
  fi
fi

# End of script
