#!/bin/bash
# MuleSoft Exchange Asset Hard Delete Tool
# File: mulesoft-hard-delete.sh

# Configuration
USERNAME="<YOUR_USERNAME>"
PASSWORD="<YOUR_PASSWORD>"
ORG_ID="<YOUR_ORG_ID>"
LIMIT=40
OFFSET=0
SEARCH=""  # Optional filter; empty for all

# Step 1: Get access token
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