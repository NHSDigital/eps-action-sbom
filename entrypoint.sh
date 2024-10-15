#!/bin/sh -l

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

# Ensure syft and grype are in PATH
export PATH="$HOME/bin:$PATH"

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
if [ -f "go.mod" ] || [ -f "go.sum" ]; then
  echo "Generating SBOM for Go packages..."
  syft -o syft-json --select-catalogers "go" dir:./ > sbom-go.json
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

# Download the check script
curl -sSfL https://raw.githubusercontent.com/NHSDigital/eps-action-sbom/refs/heads/main/check-sbom-issues-against-ignores.sh -o check-sbom-issues-against-ignores.sh
chmod +x ./check-sbom-issues-against-ignores.sh

# Allow script to continue even if errors occur
set +e
error_occurred=false

# Compare analysis results with ignored issues
for analysis in ./sbom*-analysis.json; do
    if [ -s "$analysis" ]; then
        echo "$analysis exists and has data. Comparing to ignored issues..."
        if ! ./check-sbom-issues-against-ignores.sh ./ignored_security_issues.json "$analysis"; then
            echo "Error: check-sbom-issues-against-ignores.sh failed for $analysis"
            error_occurred=true
        else
            echo "Done"
        fi
    fi
done

# Exit with an error if any errors occurred
if [ "$error_occurred" = true ]; then
    exit 1
else
    echo "All checks completed successfully."
fi
