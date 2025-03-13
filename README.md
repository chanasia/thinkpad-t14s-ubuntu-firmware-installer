# Lenovo ThinkPad T14s Gen 6 Firmware Installer
Ubuntu firmware installer script for Lenovo ThinkPad T14s Gen 6 without dual boot required.

*I followed the instructions from Ubuntu Concept Bug #2084178 (Comment #52) and adapted the default qcomm-firmware-extract.sh script from Linux-on-Snapdragon repository to create a tool that installs Qualcomm firmware without requiring a Windows partition.*

## Installation
1. Make the script executable
  ```
  chmod +x qcomm-firmware-extract-from-exe.sh
  ```

2. Run the script:
  ```
  sudo ./qcomm-firmware-extract-from-exe.sh
  ```

3. Reboot your system:
  ```
  sudo reboot
  ```

## References

This script was created based on:
- [Ubuntu Concept Bug #2084178 (Comment #52)](https://bugs.launchpad.net/ubuntu-concept/+bug/2084178/comments/52)
- Default `qcomm-firmware-extract.sh` script from [Linux-on-Snapdragon repository](https://github.com/Jeremiah-Hawley/Linux-on-Snapdragon)