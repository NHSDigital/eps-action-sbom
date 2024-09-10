#!/bin/bash

# Usage: ./check-sbom-issues-against-ignores.sh <ignored_issues_file> <scan_results_file>
IGNORED_ISSUES_FILE="$1"
SCAN_RESULTS_FILE="$2"

# Check if files exist
if [[ ! -f "$SCAN_RESULTS_FILE" ]]; then
  echo "Skipping scanning SBOM issues: missing the scan results file"
  exit 0
fi

# Read ignored issues into an array. Default to ignoring no issues.
if [[ -f "$IGNORED_ISSUES_FILE" ]]; then
  mapfile -t IGNORED_ISSUES < <(jq -r '.[]' "$IGNORED_ISSUES_FILE")
else
  IGNORED_ISSUES=()
fi

# Read scan results and check for critical vulnerabilities
CRITICAL_FOUND=false

# Loop through vulnerabilities in the scan results
while IFS= read -r MATCH; do
  VULN_ID=$(echo "$MATCH" | jq -r '.vulnerability.id')

  # Check if the vulnerability ID is in the ignored list
  FOUND=false
  for IGNORED in "${IGNORED_ISSUES[@]}"; do
    if [[ "$IGNORED" == "$VULN_ID" ]]; then
      FOUND=true
      echo "Warning: Ignored vulnerability found: $VULN_ID"
      break
    fi
  done

  # If the vulnerability is not found in the ignored list, mark critical as found
  if [[ "$FOUND" == false ]]; then
    echo "Error: Critical vulnerability found that is not in the ignore list: $VULN_ID"
    CRITICAL_FOUND=true
  fi
done < <(jq -c '.matches[] | select(.vulnerability.severity == "Critical")' "$SCAN_RESULTS_FILE")

# Exit with error if critical vulnerability is found
if [[ "$CRITICAL_FOUND" == true ]]; then
  echo "ERROR: Address the critical vulnerabilities before proceeding."
  exit 1
fi

echo "No unignored critical vulnerabilities found."
exit 0