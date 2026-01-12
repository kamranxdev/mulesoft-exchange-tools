#!/bin/bash

# Secure Property Tool Wrapper
# A simple wrapper for the MuleSoft Secure Properties Tool JAR.
# Simplifies the syntax for encrypting and decrypting strings.

# Dependencies: java

set -e

# Configuration
# You can hardcode the path to your jar here, or pass it via JAR_PATH env var
DEFAULT_JAR_PATH="./secure-properties-tool.jar"
JAR_PATH="${JAR_PATH:-$DEFAULT_JAR_PATH}"

# Default Algorithm and Mode
ALGORITHM="Blowfish"
MODE="CBC"

usage() {
    echo "Usage: $0 <action> <key> <value> [algorithm] [mode]"
    echo "  action    : encrypt | decrypt"
    echo "  key       : Your encryption key"
    echo "  value     : The string to encrypt/decrypt"
    echo "  algorithm : (Optional) Blowfish (default), AES, ACES, etc."
    echo "  mode      : (Optional) CBC (default), CFB, ECB, OFB"
    echo ""
    echo "  Note: Ensure 'secure-properties-tool.jar' is in the current directory or set JAR_PATH."
    exit 1
}

if [[ "$#" -lt 3 ]]; then
    usage
fi

ACTION="$1"
KEY="$2"
VALUE="$3"
ALGORITHM="${4:-$ALGORITHM}"
MODE="${5:-$MODE}"

# Validate Action
if [[ "$ACTION" != "encrypt" && "$ACTION" != "decrypt" ]]; then
    echo "Error: Action must be 'encrypt' or 'decrypt'."
    exit 1
fi

# Check if Java is installed
command -v java >/dev/null 2>&1 || { echo >&2 "Error: Java is not installed."; exit 1; }

# Check for JAR
if [[ ! -f "$JAR_PATH" ]]; then
    echo "Error: Secure Properties Tool JAR not found at '$JAR_PATH'."
    echo "Please download it from MuleSoft and place it here, or export JAR_PATH=/path/to/jar"
    exit 1
fi

# Execute
# Syntax: java -jar secure-properties-tool.jar string <action> <algorithm> <mode> <key> <value>
echo "Running MuleSoft Secure Properties Tool..."

java -jar "$JAR_PATH" string "$ACTION" "$ALGORITHM" "$MODE" "$KEY" "$VALUE"

echo "" # Newline
