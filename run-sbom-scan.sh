#!/bin/bash

set -e

# Remove any existing SBOMs
rm -f ./sbom*.json

asdf install

# Set up NPM token if provided
if [ -n "$NPM_AUTH_TOKEN" ]; then
  echo "Setting up .npmrc with provided NPM_AUTH_TOKEN..."
  mkdir -p $HOME/.npm
  echo "//npm.pkg.github.com/:_authToken=${NPM_AUTH_TOKEN}" >> $HOME/.npmrc
  echo "@nhsdigital:registry=https://npm.pkg.github.com" >> $HOME/.npmrc
  echo "NPM token setup complete."
else
  echo "No NPM_AUTH_TOKEN provided; skipping NPM authentication setup."
fi

# Run make install
make install

# Install Syft
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Install Grype
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Ensure syft and grype are in PATH
export PATH="/usr/local/bin:$PATH"

# Generate SBOMs for NPM packages
if [ -f "package.json" ]; then
  echo "Generating SBOM for NPM packages..."
  syft dir:./ --catalogers npm-package-cataloger -o syft-json -o sbom-node.json
  echo "Done"
fi

# Generate SBOMs for Python packages
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  echo "Generating SBOM for Python packages..."
  syft dir:./ --catalogers python-package-cataloger -o syft-json -o sbom-python.json
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
curl -sSfL https://raw.githubusercontent.com/NHSDigital/eps-action-sbom/refs/heads/aea-0000-move-to-syft/check-sbom-issues-against-ignores.sh -o check-sbom-issues-against-ignores.sh
chmod +x ./check-sbom-issues-against-ignores.sh

# Run the check script
./check-sbom-issues-against-ignores.sh ./ignored_security_issues.json
