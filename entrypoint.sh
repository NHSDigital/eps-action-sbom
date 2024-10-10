#!/bin/sh -l

set -e

# Remove any existing SBOMs
rm -f ./sbom*.json

# Fix ASDF environment variables if necessary
if [ -n "${ASDF_DIR}" ]; then
    echo "ASDF_DIR not set. Copying in local installation of ASDF..."
    mkdir -p "${ASDF_DIR}"
    cp -r /root/.asdf/* "${ASDF_DIR}"/
fi
asdf reshim

# Build the project. Assumes that we have makefile commands in line with 
# https://nhsd-confluence.digital.nhs.uk/display/APIMC/Git+repository+checklist
# If being used with quality-checks workflow, this is redundant!
make install

# Generate SBOM for NPM packages
if [ -f "package.json" ]; then
    echo "Generating SBOM for NPM packages..."
    syft dir:./ --catalogers npm-package-cataloger -o syft-json -o sbom-node.json
    echo "Done"
fi

# Generate SBOM for Python packages
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

# Allow script to continue even if errors occur
set +e
error_occurred=false

# Compare analysis results with ignored issues
for analysis in ./sbom*-analysis.json; do
    if [ -s "$analysis" ]; then
        echo "$analysis exists and has data. Comparing to ignored issues..."
        if ! /check-sbom-issues-against-ignores.sh ./ignored_security_issues.json "$analysis"; then
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
