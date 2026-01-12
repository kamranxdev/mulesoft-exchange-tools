#!/bin/bash

# Bulk CloudHub Scheduler Manager
# This script enables bulk Start/Stop of CloudHub application schedules based on name patterns.

# Dependencies: curl, jq

set -e

# Default values
USERNAME=""
PASSWORD=""
ENV_ID=""
ACTION="" # START or STOP
PATTERN=""
DRY_RUN=false

# Function to display usage
usage() {
    echo "Usage: $0 --username <user> --password <pass> --env_id <id> --action <START|STOP> --pattern <regex> [--dry-run]"
    echo "  --username  MuleSoft Username"
    echo "  --password  MuleSoft Password"
    echo "  --env_id    Environment ID"
    echo "  --action    Action to perform: START or STOP"
    echo "  --pattern   Regex pattern to match application names (e.g., '.*-dev')"
    echo "  --dry-run   Simulate the action without applying changes"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --username) USERNAME="$2"; shift ;;
        --password) PASSWORD="$2"; shift ;;
        --env_id) ENV_ID="$2"; shift ;;
        --action) ACTION="$2"; shift ;;
        --pattern) PATTERN="$2"; shift ;;
        --dry-run) DRY_RUN=true ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

if [[ -z "$USERNAME" || -z "$PASSWORD" || -z "$ENV_ID" || -z "$ACTION" || -z "$PATTERN" ]]; then
    echo "Error: Missing required arguments."
    usage
fi

if [[ "$ACTION" != "START" && "$ACTION" != "STOP" ]]; then
    echo "Error: Action must be START or STOP."
    exit 1
fi

echo "Authenticating..."
ACCESS_TOKEN=$(curl -s -X POST https://anypoint.mulesoft.com/accounts/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$USERNAME\", \"password\":\"$PASSWORD\"}" | jq -r .access_token)

if [[ "$ACCESS_TOKEN" == "null" || -z "$ACCESS_TOKEN" ]]; then
    echo "Authentication failed."
    exit 1
fi

echo "Listing applications in Environment $ENV_ID matching pattern '$PATTERN'..."

# List Applications (CloudHub 1.0 Example - API varies for CH 2.0/RTF)
APPS_RESPONSE=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "X-ANYPNT-ENV-ID: $ENV_ID" \
    "https://anypoint.mulesoft.com/cloudhub/api/v2/applications")

# Echoing logic
echo "$APPS_RESPONSE" | jq -r '.[].domain' | grep -E "$PATTERN" | while read -r app_name; do
    echo "Found target app: $app_name"
    
    # Get Schedules for this App
    # Retrieve schedules - Note: Endpoint assumes CloudHub 1.0 structure
    SCHEDULES=$(curl -s -H "Authorization: Bearer $ACCESS_TOKEN" \
        -H "X-ANYPNT-ENV-ID: $ENV_ID" \
        "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$app_name/schedules")
    
    echo "$SCHEDULES" | jq -c '.[]' | while read -r schedule; do
        sched_id=$(echo "$schedule" | jq -r .id)
        sched_name=$(echo "$schedule" | jq -r .name)
        
        echo "  - Schedule: $sched_name ($sched_id)"
        
        if [ "$DRY_RUN" = true ]; then
            echo "    [DRY RUN] Would $ACTION schedule $sched_id"
        else
            echo "    $ACTION-ing schedule $sched_id..."
            # Payload for PUT
            # State is 'CHECKED' (Enabled) or 'UNCHECKED' (Disabled) usually, or 'start'/'stop' depending on specific API version
            # CloudHub Scheduler API uses "enabled": true/false
            
            ENABLED_VAL="true"
            if [ "$ACTION" == "STOP" ]; then
                ENABLED_VAL="false"
            fi
            
            # Update Schedule
            UPDATE_RESPONSE=$(curl -s -X PUT \
                -H "Authorization: Bearer $ACCESS_TOKEN" \
                -H "X-ANYPNT-ENV-ID: $ENV_ID" \
                -H "Content-Type: application/json" \
                -d "{\"enabled\": $ENABLED_VAL}" \
                "https://anypoint.mulesoft.com/cloudhub/api/v2/applications/$app_name/schedules/$sched_id")
            
            echo "    Result: Done."
        fi
    done
done

echo "Bulk Operation Completed."
