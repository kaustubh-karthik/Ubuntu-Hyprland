#!/bin/bash
# 💫 https://github.com/JaKooLit 💫 #
# Main Hyprland Package#


#specific branch or release
hyprland_tag="v0.39.1"

## WARNING: DO NOT EDIT BEYOND THIS LINE IF YOU DON'T KNOW WHAT YOU ARE DOING! ##
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Change the working directory to the parent directory of the script
PARENT_DIR="$SCRIPT_DIR/.."
cd "$PARENT_DIR" || { echo "${ERROR} Failed to change directory to $PARENT_DIR"; exit 1; }

# Source the global functions script
if ! source "$(dirname "$(readlink -f "$0")")/Global_functions.sh"; then
  echo "Failed to source Global_functions.sh"
  exit 1
fi

# Set the name of the log file to include the current date and time
LOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland.log"
MLOG="Install-Logs/install-$(date +%d-%H%M%S)_hyprland-compile.log"

# Check for necessary build dependencies
echo "${INFO} Checking and installing build dependencies for Hyprland..." | tee -a "$LOG"
sudo apt update -y 2>&1 | tee -a "$LOG"
sudo apt install -y build-essential cmake ninja-build libwayland-dev libwayland-server0 wayland-protocols \
  libgbm-dev libdrm-dev libinput-dev libxkbcommon-dev libudev-dev meson libpixman-1-dev \
  libseat-dev hwdata libdisplay-info-dev libliftoff-dev libvulkan-dev glslang-tools 2>&1 | tee -a "$LOG"

# Clone, build, and install Hyprland using Cmake
printf "${INFO} Compiling and Installing ${YELLOW}hyprland $hyprland_tag${RESET} from source ...\n" | tee -a "$LOG"

# Check if Hyprland directory exists and remove it
if [ -d "Hyprland" ]; then
  echo "${INFO} Removing existing Hyprland directory..." | tee -a "$LOG"
  rm -rf "Hyprland" 2>&1 | tee -a "$LOG"
fi

echo "${INFO} Cloning Hyprland repository..." | tee -a "$LOG"
if git clone --recursive -b $hyprland_tag "https://github.com/hyprwm/Hyprland" 2>&1 | tee -a "$LOG"; then
  cd "Hyprland" || { echo "${ERROR} Failed to change directory to Hyprland"; exit 1; }
  
  echo "${INFO} Building Hyprland..." | tee -a "$PARENT_DIR/$MLOG"
  # Check for required files first (CMakeLists.txt)
  if [ ! -f "CMakeLists.txt" ]; then
    echo "${ERROR} CMakeLists.txt not found in Hyprland directory. Repository may be incomplete." | tee -a "$PARENT_DIR/$LOG" "$PARENT_DIR/$MLOG"
    exit 1
  fi
  
  # Run make with verbose output 
  make all VERBOSE=1 2>&1 | tee -a "$PARENT_DIR/$MLOG"
  
  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    echo "${INFO} Hyprland build successful. Installing..." | tee -a "$PARENT_DIR/$LOG" "$PARENT_DIR/$MLOG"
    
    # Install with sudo and verbose output
    if sudo make install 2>&1 | tee -a "$PARENT_DIR/$MLOG"; then
      echo "${OK} ${MAGENTA}hyprland $hyprland_tag${RESET} has been successfully installed." | tee -a "$PARENT_DIR/$LOG" "$PARENT_DIR/$MLOG"
      
      # Verify binary installation
      if [ -f "/usr/local/bin/Hyprland" ]; then
        echo "${OK} Verified Hyprland binary is installed at /usr/local/bin/Hyprland" | tee -a "$PARENT_DIR/$LOG"
  else
        echo "${WARN} Hyprland binary not found at /usr/local/bin/Hyprland" | tee -a "$PARENT_DIR/$LOG"
        # Create symbolic link if it's installed elsewhere but not in the expected location
        if [ -f "./build/Hyprland" ]; then
          echo "${INFO} Found Hyprland binary in build directory. Creating symbolic link..." | tee -a "$PARENT_DIR/$LOG"
          sudo ln -sf "$(pwd)/build/Hyprland" /usr/local/bin/Hyprland
          sudo ln -sf /usr/local/bin/Hyprland /usr/local/bin/hyprland
          echo "${OK} Created symbolic links for Hyprland" | tee -a "$PARENT_DIR/$LOG"
        fi
      fi
    else
      echo "${ERROR} Installation failed for ${YELLOW}hyprland $hyprland_tag${RESET}" | tee -a "$PARENT_DIR/$LOG" "$PARENT_DIR/$MLOG"
  fi
  else
    echo "${ERROR} Build failed for ${YELLOW}hyprland $hyprland_tag${RESET}. Check logs for details." | tee -a "$PARENT_DIR/$LOG" "$PARENT_DIR/$MLOG"
  fi
  
  cd "$PARENT_DIR" || { echo "${ERROR} Failed to return to parent directory"; exit 1; }
else
  echo "${ERROR} Download failed for ${YELLOW}hyprland $hyprland_tag${RESET}" | tee -a "$LOG"
fi

# Install session file
wayland_sessions_dir=/usr/share/wayland-sessions
[ ! -d "$wayland_sessions_dir" ] && { printf "$CAT - $wayland_sessions_dir not found, creating...\n" | tee -a "$LOG"; sudo mkdir -p "$wayland_sessions_dir" 2>&1 | tee -a "$LOG"; }
sudo cp assets/hyprland.desktop "$wayland_sessions_dir/" 2>&1 | tee -a "$LOG"

# Create a symbolic link for lowercase 'hyprland' command if it doesn't exist
if [ -f "/usr/local/bin/Hyprland" ] && [ ! -f "/usr/local/bin/hyprland" ]; then
  echo "${INFO} Creating symbolic link from Hyprland to hyprland..." | tee -a "$LOG"
  sudo ln -sf /usr/local/bin/Hyprland /usr/local/bin/hyprland
fi

# Final verification
echo "${INFO} Verifying Hyprland installation..." | tee -a "$LOG"
if [ -f "/usr/local/bin/Hyprland" ] || [ -f "/usr/local/bin/hyprland" ]; then
  echo "${OK} Hyprland is successfully installed!" | tee -a "$LOG"
else
  echo "${ERROR} Hyprland installation verification failed. Could not find Hyprland in /usr/local/bin/" | tee -a "$LOG"
fi

printf "\n%.0s" {1..2}

