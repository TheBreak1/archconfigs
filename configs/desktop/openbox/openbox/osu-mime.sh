#!/bin/bash

# Placeholder script for osu-mime configuration
# Goal is to make a script that changes opening osu! files between stable and lazer
# This should be divided into two separate scripts later for each menu button.

# Function to show error dialog
show_hello_world() {
    xmessage -center -title "Hello World" "Hello world" &
}

# Check if we're in an Openbox session
if [ -n "$OPENBOX_PID" ] || pgrep -x "openbox" > /dev/null; then
    show_hello_world
else
    echo "Warning: Openbox not detected. This script is designed for Openbox window manager."
    echo "Hello world"
fi
