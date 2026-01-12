#!/bin/bash

# Deployment Property Validator
# Scans MuleSoft project code for placeholders like \${http.port} and checks if they exist in a property file.

set -e

PROJECT_DIR=""
PROP_FILE=""

usage() {
    echo "Usage: $0 --project <project_path> --properties <property_file>"
    echo "  --project     Path to the MuleSoft project directory (containing xml/dwl files)"
    echo "  --properties  Path to the YAML/Properties file to check against"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --project) PROJECT_DIR="$2"; shift ;;
        --properties) PROP_FILE="$2"; shift ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

if [[ -z "$PROJECT_DIR" || -z "$PROP_FILE" ]]; then
    echo "Error: Project directory and Property file are required."
    usage
fi

if [[ ! -f "$PROP_FILE" ]]; then
    echo "Error: Property file $PROP_FILE not found."
    exit 1
fi

echo "Scanning '$PROJECT_DIR' for property placeholders..."

# Find all placeholders like ${foo.bar} or ${foo}
# Regex breakdown:
# \$\{       : Literal ${
# ([^}]+)    : Capture group for anything that is NOT a closing brace
# \}         : Literal }
# We use grep -r to recursive search, o to show only match, h to suppress filename
PLACEHOLDERS=$(grep -r -o -h "\${[^}]*}" "$PROJECT_DIR" --include="*.xml" --include="*.dwl" | sed 's/[${}]//g' | sort | uniq)

echo "Found the following placeholders in code:"
echo "$PLACEHOLDERS" | sed 's/^/  - /'

echo -e "\nValidating against $PROP_FILE..."

MISSING_COUNT=0

# Iterate through each placeholder
while read -r key; do
    if [[ -z "$key" ]]; then continue; fi

    # Check if key exists in property file.
    # Simple check for "key:" or "key="
    # This is a basic check. For nested YAML, a parser like 'yq' is better, but trying to keep dependencies low.
    # We'll check if the string "key" appears in the file. Ideally we check if it is a key.
    
    if grep -q -E "^(\s*)$key[:=]" "$PROP_FILE" || grep -q -E "\"$key\"[:=]" "$PROP_FILE"; then
        # echo "  OK: $key" # Uncomment for verbose
        :
    else
        echo "  [MISSING] Property '$key' is used in code but NOT found in $PROP_FILE"
        MISSING_COUNT=$((MISSING_COUNT + 1))
    fi
done <<< "$PLACEHOLDERS"

if [[ "$MISSING_COUNT" -gt 0 ]]; then
    echo -e "\nFAILURE: Found $MISSING_COUNT missing properties."
    exit 1
else
    echo -e "\nSUCCESS: All placeholders appear to be defined."
    exit 0
fi
