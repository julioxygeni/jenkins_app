#!/bin/bash
# Config reader script - loads app configuration before build
# WARNING: any PR can modify this script; the pipeline executes it without prior review (indirect PPE)

CONFIG_FILE="${1:-config/app-config.txt}"

echo "Reading configuration from: $CONFIG_FILE"
cat "$CONFIG_FILE"
