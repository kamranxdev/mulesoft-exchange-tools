#!/bin/bash
# MuleSoft Exchange Asset Hard Delete Tool
# File: mulesoft-hard-delete.sh

# Function to display usage
usage() {
  echo "Usage: $0 -u <username> -p <password> -o <org_id> [options]"
  echo ""
  echo "Options:"
  echo "  -u, --username <username>   MuleSoft Username (Required)"
  echo "  -p, --password <password>   MuleSoft Password (Required)"
  echo "  -o, --org-id <org_id>       Organization ID (Required)"
  echo "  -l, --limit <limit>         Limit results (default: 40)"
  echo "  --offset <offset>           Offset results (default: 0)"
  echo "  -s, --search <search>       Search filter"
  echo "  -h, --help                  Show this help message"
  exit 1
}

# Default values
LIMIT=40
OFFSET=0
SEARCH=""

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    -u|--username) USERNAME="$2"; shift ;;
    -p|--password) PASSWORD="$2"; shift ;;
    -o|--org-id) ORG_ID="$2"; shift ;;
    -l|--limit) LIMIT="$2"; shift ;;
    --offset) OFFSET="$2"; shift ;;
    -s|--search) SEARCH="$2"; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Validate required arguments
if [ -z "${USERNAME}" ] || [ -z "${PASSWORD}" ] || [ -z "${ORG_ID}" ]; then
  echo "Error: Missing required arguments."
  usage
fi

TOKEN_RESPONSE=$(curl -s -X POST \
  https://anypoint.mulesoft.com/accounts/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"${USERNAME}\",\"password\":\"${PASSWORD}\"}")

TOKEN=$(echo "${TOKEN_RESPONSE}" | jq -r '.access_token // empty')

if [ -z "${TOKEN}" ] || [ "${TOKEN}" = "null" ]; then
  echo "❌ Login failed."
  exit 1
fi

echo "✅ Token obtained successfully."

# Step 2: List soft deleted assets
SOFT_DELETED=$(curl -s "https://anypoint.mulesoft.com/exchange/api/v2/organizations/${ORG_ID}/softDeleted?limit=${LIMIT}&offset=0${SEARCH:+&search=${SEARCH}}" \
  -H "Authorization: Bearer ${TOKEN}")

echo "${SOFT_DELETED}" | jq '.'

# Step 3: Interactive delete option
ASSETS=$(echo "${SOFT_DELETED}" | jq -r '.[] | "\(.organizationId)|\(.groupId)|\(.assetId)|\(.version)"')

if [ "$(echo "${SOFT_DELETED}" | jq '. | length')" -eq 0 ]; then
  echo "No soft deleted assets found."
  exit 0
fi

echo ""
echo "Select asset to HARD DELETE (permanent, no recovery! Type index or 'q' to quit):"
echo "${ASSETS}" | awk -F'|' '{print $3 " v" $4}' | nl -w2 -s'. '

read -r INDEX

if [[ "${INDEX}" =~ ^[0-9]+$ ]] && [ "${INDEX}" -ge 1 ] && [ "${INDEX}" -le "$(echo "${ASSETS}" | wc -l)" ]; then
  SELECTED=$(echo "${ASSETS}" | sed -n "${INDEX}p")
  ORG=$(echo "${SELECTED}" | cut -d'|' -f1)
  GROUP=$(echo "${SELECTED}" | cut -d'|' -f2)
  ASSET=$(echo "${SELECTED}" | cut -d'|' -f3)
  VERSION=$(echo "${SELECTED}" | cut -d'|' -f4)
  
  echo "⚠️  Deleting ${GROUP}/${ASSET}/${VERSION}..."
  
  # Correct API endpoint format
  DELETE_RESPONSE=$(curl -s -X DELETE \
    "https://anypoint.mulesoft.com/exchange/api/v2/assets/${GROUP}/${ASSET}/${VERSION}" \
    -H "Authorization: Bearer ${TOKEN}" \
    -H "x-delete-type: hard-delete")
  
  echo "${DELETE_RESPONSE}" | jq '.'
  
  # Check if deletion was successful
  if echo "${DELETE_RESPONSE}" | jq -e '.status == 404' > /dev/null 2>&1; then
    echo ""
    echo "❌ Delete failed with 404. Trying alternative endpoint..."
    
    # Try with organization ID in path
    ALT_RESPONSE=$(curl -s -X DELETE \
      "https://anypoint.mulesoft.com/exchange/api/v2/organizations/${ORG}/assets/${GROUP}/${ASSET}/${VERSION}" \
      -H "Authorization: Bearer ${TOKEN}" \
      -H "x-delete-type: hard-delete")
    
    echo "${ALT_RESPONSE}" | jq '.'
    
    if echo "${ALT_RESPONSE}" | jq -e '.status' > /dev/null 2>&1; then
      echo "❌ Alternative endpoint also failed."
    else
      echo "✅ Hard delete completed via alternative endpoint."
    fi
  else
    echo "✅ Hard delete completed."
  fi
else
  echo "Cancelled."
fi