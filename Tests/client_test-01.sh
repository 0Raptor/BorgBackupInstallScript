#!/bin/bash

# Test01 - Check if SSH connection can be established
#  This test is only applicable to an client-server infrastructure

# Please enter your setup information here
#  name of the backupserver configured during installation
backupservername="backup"

echo "Test01 - Validate SSH"
echo " Establishing connection..."
echo "  - Confirm identity with yes"
echo "  - Wait a few seconds"
echo "  - Terminate connection with Ctrl+C"
echo ""
#establish ssh connection
ssh $backupservername
echo ""
echo "  --> Above should be a text like:"
echo "   ^C$LOG ERROR borg.archiver Remote: Keyboard interrupt"
echo "   Connection to %backupserverFQDN% closed."
echo ""
echo " Done."
