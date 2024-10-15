#!/bin/bash -l

set -e

# Remove any existing SBOMs
rm -f ./sbom*.json

# If the current github workflow has installed asdf, it will pass the ASDF_DIR and ASDF_DATA_DIR
# environment variables in to the action, overriding this docker container's installation and leaving it
# unable to find the scripts.
# Here, we check if these variables are set, and if necessary we copy in our local installation of asdf.
if [ -n "${ASDF_DIR}" ]; then
    echo "ASDF_DIR has been provided: ${ASDF_DIR}"
else
  export ASDF_DIR="/root/.asdf/"
fi
export PATH="$PATH:$ASDF_DIR/bin:$ASDF_DIR/shims"
asdf reshim
asdf install

# Set up NPM token if provided
if [ -n "$GITHUB_TOKEN" ]; then
  echo "Setting up .npmrc with provided GITHUB_TOKEN..."
  mkdir -p "$HOME"/.npm
  echo "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}" >> "$HOME"/.npmrc
  echo "@nhsdigital:registry=https://npm.pkg.github.com" >> "$HOME"/.npmrc
  echo "NPM token setup complete."
else
  echo "No GITHUB_TOKEN provided; skipping NPM authentication setup."
fi

# Run make install
make install

# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/c2c8c793d2ba6bee90b5fa1a2369912d76304a79/install.sh | sh -s -- -b "$HOME"/bin

# Install Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/71d05d2509a4f4a9d34a0de5cb29f55ddb6f72c1/install.sh | sh -s -- -b "$HOME"/bin

# Ensure syft, grype, and jq are in PATH
export PATH="$HOME/bin:$PATH"

# Install jq if not already installed
if ! command -v jq > /dev/null; then
  echo "Installing jq..."
  JQ_URL="https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64"
  curl -L -o "$HOME/bin/jq" "$JQ_URL"
  chmod +x "$HOME/bin/jq"
  echo "jq installed."
else
  echo "jq is already installed."
fi

# Generate SBOMs for NPM packages
if [ -f "package.json" ]; then
  echo "Generating SBOM for NPM packages..."
  syft -o syft-json --select-catalogers "npm" dir:./ > sbom-npm.json
  echo "Done"
fi

# Generate SBOMs for Python packages
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  echo "Generating SBOM for Python packages..."
  syft -o syft-json --select-catalogers "python" dir:./ > sbom-python.json
  echo "Done"
fi

# Generate SBOMs for Go packages
if [ -f "go.mod" ] || [ -f "go.sum" ] || [ -d "vendor" ] || ls ./*.go 1> /dev/null 2>&1; then
  echo "Generating SBOM for Go packages..."
  syft -o syft-json --select-catalogers "go" dir:. > "sbom-golang.json"
  echo "Done"
fi

# Scan each SBOM with Grype
for sbom in ./sbom*.json; do
  if [ -s "$sbom" ]; then
    echo "$sbom exists and has data. Scanning with Grype..."
    grype sbom:"$sbom" -o json > "$(basename "$sbom" .json)-analysis.json"
    echo "Done"
  fi
done

# Allow script to continue even if errors occur
set +e
error_occurred=false

# Compare analysis results with ignored issues
for analysis in ./sbom*-analysis.json; do
  if [ -s "$analysis" ]; then
    echo "$analysis exists and has data. Comparing to ignored issues..."

    # Begin integrated code from check-sbom-issues-against-ignores.sh
    IGNORED_ISSUES_FILE="./ignored_security_issues.json"
    SCAN_RESULTS_FILE="$analysis"

    # Check if the scan results file exists
    if [ ! -f "$SCAN_RESULTS_FILE" ]; then
      echo "Skipping scanning SBOM issues: missing the scan results file"
      continue
    fi

    # Read ignored issues into an array. Default to ignoring no issues.
    if [ -f "$IGNORED_ISSUES_FILE" ]; then
      mapfile -t IGNORED_ISSUES < <(jq -r '.[]' "$IGNORED_ISSUES_FILE")
    else
      IGNORED_ISSUES=()
    fi

    # Report the list of ignored issues
    echo "***************************"
    echo "Ignoring the following issues:"
    echo " "
    for IGNORED in "${IGNORED_ISSUES[@]}"; do
      echo "    $IGNORED"
    done
    echo "***************************"

    # Read scan results and check for critical vulnerabilities
    CRITICAL_FOUND=false

    # Loop through vulnerabilities in the scan results
    while IFS= read -r MATCH; do
      VULN_ID=$(echo "$MATCH" | jq -r '.vulnerability.id')
      DESCRIPTION=$(echo "$MATCH" | jq -r '.vulnerability.description')
      DATASOURCE=$(echo "$MATCH" | jq -r '.vulnerability.dataSource')

      # Check if the vulnerability ID is in the ignored list
      FOUND=false
      for IGNORED in "${IGNORED_ISSUES[@]}"; do
        if [ "$IGNORED" = "$VULN_ID" ]; then
          FOUND=true
          echo
          echo "***************************"
          echo "Warning: Ignored vulnerability found: $VULN_ID"
          echo "Warning: Description: $DESCRIPTION"
          echo "Warning: dataSource: $DATASOURCE"
          echo "***************************"
          break
        fi
      done

      # If the vulnerability is not found in the ignored list, mark critical as found
      if [ "$FOUND" = false ]; then
        echo
        echo "***************************"
        echo "Error: Critical vulnerability found that is not in the ignore list: $VULN_ID"
        echo "Error: Description: $DESCRIPTION"
        echo "Error: dataSource: $DATASOURCE"
        echo "***************************"
        CRITICAL_FOUND=true
      fi
    done < <(jq -c '.matches[] | select(.vulnerability.severity == "Critical")' "$SCAN_RESULTS_FILE")

    # If critical vulnerabilities found, set error_occurred to true
    if [[ "$CRITICAL_FOUND" == true ]]; then
      echo "ERROR: Address the critical vulnerabilities before proceeding."
      echo "To add this to an ignore list, add the vulnerability to ignored_security_issues.json"
      echo "See https://github.com/NHSDigital/eps-action-sbom for more details"
      error_occurred=true
    else
      echo "No unignored critical vulnerabilities found."
    fi

    echo "Done"
  fi
done

# Exit with an error if any errors occurred
if [ "$error_occurred" = true ]; then
    exit 1
else
    echo "All checks completed successfully."
fi
