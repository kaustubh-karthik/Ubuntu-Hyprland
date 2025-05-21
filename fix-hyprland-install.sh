#!/bin/bash
# Fix script for Hyprland installation

# Set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"

# Create logs directory if it doesn't exist
if [ ! -d "Fix-Logs" ]; then
    mkdir Fix-Logs
fi

# Set log file
LOG="Fix-Logs/fix-hyprland-$(date +%d-%H%M%S).log"

echo "${INFO} Starting Hyprland installation fix..." | tee -a "$LOG"

# Install all required dependencies
echo "${INFO} Installing dependencies required for Hyprland..." | tee -a "$LOG"
sudo apt update -y 2>&1 | tee -a "$LOG"
sudo apt install -y cmake ninja-build meson wget curl git build-essential libpango1.0-dev \
  libgbm-dev libdrm-dev libwayland-dev libwayland-server0 wayland-protocols \
  libinput-dev libxkbcommon-dev libudev-dev libpixman-1-dev libseat-dev hwdata \
  libdisplay-info-dev libliftoff-dev libvulkan-dev glslang-tools 2>&1 | tee -a "$LOG"

# Remove any existing Hyprland installation
echo "${INFO} Cleaning up any existing Hyprland installations..." | tee -a "$LOG"
sudo rm -f /usr/local/bin/Hyprland /usr/local/bin/hyprland 2>&1 | tee -a "$LOG"
sudo rm -rf /usr/local/share/hyprland 2>&1 | tee -a "$LOG" 

# Cleanup any existing build directory
echo "${INFO} Cleaning up any existing Hyprland build directories..." | tee -a "$LOG"
if [ -d "Hyprland" ]; then
  echo "${INFO} Removing existing Hyprland directory..." | tee -a "$LOG"
  rm -rf "Hyprland" 2>&1 | tee -a "$LOG"
fi

# Clone Hyprland with specific tag
HYPRLAND_TAG="v0.39.1"
echo "${INFO} Cloning Hyprland repository (tag: ${HYPRLAND_TAG})..." | tee -a "$LOG"
if ! git clone --recursive -b ${HYPRLAND_TAG} "https://github.com/hyprwm/Hyprland" 2>&1 | tee -a "$LOG"; then
  echo "${ERROR} Failed to clone Hyprland repository. Please check your internet connection." | tee -a "$LOG"
  exit 1
fi

# Navigate to Hyprland directory
cd Hyprland || { echo "${ERROR} Failed to change directory to Hyprland"; exit 1; }

# Build Hyprland with explicit configuration
echo "${INFO} Building Hyprland..." | tee -a "$PARENT_DIR/$LOG"
cmake -B build -GNinja . 2>&1 | tee -a "../$LOG"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "${ERROR} CMake configuration failed. Checking for error..." | tee -a "../$LOG"
  exit 1
fi

# Build using ninja
echo "${INFO} Compiling Hyprland with ninja..." | tee -a "../$LOG"
ninja -C build 2>&1 | tee -a "../$LOG"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "${ERROR} Compilation failed." | tee -a "../$LOG"
  exit 1
fi

# Install Hyprland
echo "${INFO} Installing Hyprland..." | tee -a "../$LOG"
sudo ninja -C build install 2>&1 | tee -a "../$LOG"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "${ERROR} Installation failed." | tee -a "../$LOG"
  exit 1
fi

# Create symbolic link for lowercase command
if [ -f "/usr/local/bin/Hyprland" ] && [ ! -f "/usr/local/bin/hyprland" ]; then
  echo "${INFO} Creating symbolic link for lowercase command..." | tee -a "../$LOG"
  sudo ln -sf /usr/local/bin/Hyprland /usr/local/bin/hyprland 2>&1 | tee -a "../$LOG"
fi

# Verify installation
cd .. || { echo "${ERROR} Failed to return to parent directory"; exit 1; }
echo "${INFO} Verifying Hyprland installation..." | tee -a "$LOG"
if [ -f "/usr/local/bin/Hyprland" ]; then
  echo "${OK} ${MAGENTA}Hyprland${RESET} has been successfully installed at /usr/local/bin/Hyprland!" | tee -a "$LOG"
  
  # Ensure desktop file exists
  echo "${INFO} Installing desktop file..." | tee -a "$LOG"
  sudo mkdir -p /usr/share/wayland-sessions/ 2>&1 | tee -a "$LOG"
  sudo cp assets/hyprland.desktop /usr/share/wayland-sessions/ 2>&1 | tee -a "$LOG"
  
  echo "${OK} ${MAGENTA}Hyprland${RESET} installation complete!" | tee -a "$LOG"
  echo "${NOTE} You can now start Hyprland by typing ${SKY_BLUE}Hyprland${RESET} or ${SKY_BLUE}hyprland${RESET}"
  echo "${NOTE} It is recommended to reboot your system before using Hyprland."
else
  echo "${ERROR} Hyprland installation verification failed." | tee -a "$LOG"
  echo "${NOTE} Please check the logs in Fix-Logs/ directory for details."
  exit 1
fi 