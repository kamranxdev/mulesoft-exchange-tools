#!/bin/bash

# Anypoint VPC & DLB Audit Tool
# This script exports configurations for all VPCs and DLBs in an Organization.

# Dependencies: curl, jq

set -e

# Default values
USERNAME=""
PASSWORD=""
ORG_ID=""
OUTPUT_FILE="vpc_dlb_audit.json"

# Function to display usage
usage() {
    echo "Usage: $0 --username <user> --password <pass> --org_id <org_id> [--output <file>]"
    echo "  --username  MuleSoft Username"
    echo "  --password  MuleSoft Password"
    echo "  --org_id    Organization ID (VPCs are Org-level)"
    echo "  --output    Output JSON file (Default: vpc_dlb_audit.json)"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --username) USERNAME="$2"; shift ;;
        --password) PASSWORD="$2"; shift ;;
        --org_id) ORG_ID="$2"; shift ;;
        --output) OUTPUT_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$ORG_ID" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

echo "Authenticating..."
ACCESS_TOKEN=$(curl -s -X POST https://anypoint.mulesoft.com/accounts/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" | jq -r .access_token)

if [[ "$ACCESS_TOKEN" == "null" || -z "$ACCESS_TOKEN" ]]; then
    echo "Authentication failed."
    exit 1
fi

echo "Fetching VPCs..."
VPCS=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-ANYPNT-ORG-ID: $ORG_ID" \
    "https://anypoint.mulesoft.com/cloudhub/api/vpcs")

echo "Fetching DLBs..."
DLBS=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-ANYPNT-ORG-ID: $ORG_ID" \
    "https://anypoint.mulesoft.com/cloudhub/api/vpcs/load-balancers")

# Combine results into one JSON
echo "Generating Audit Report..."

cat <<EOF > "$OUTPUT_FILE"
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "organizationId": "$ORG_ID",
  "vpcs": $VPCS,
  "loadBalancers": $DLBS
}
EOF

echo "Audit Complete. Report saved to $OUTPUT_FILE"
