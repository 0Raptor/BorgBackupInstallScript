#!/bin/bash
clear
echo "USB-Drive-Encryption Preparation"

echo ""
[ "$UID" -eq 0 ] || echo "Hello $(whoami)! Root-privileges are required to setup and configure BorgBackup."
[ "$UID" -eq 0 ] || exec sudo "$0" "$@"

echo "Enter drive to encrypt (e.g. /dev/sdb)"
read drive