#!/bin/sh -l

# Remove any existing SBOMs
rm -f ./sbom*.json

# Scan the dependencies for NPM
if [ -f "package.json" ] && [ -f "package-lock.json" ]; then
    echo "Generating SBOM for Node.js..."
    # The node_modules directory is not needed for generating the SBOM
    npm install
    cyclonedx-npm --output-format json --output-file sbom-node.json
    echo "Done"
else
    echo "package.json and package-lock.json not found. Cannot generate Node.js SBOM."
fi

# Repeat the above steps for Python
# Check if pyproject.toml (Poetry) or requirements.txt exists
if [ -f "pyproject.toml" ]; then
    echo "Detected Poetry project. Generating SBOM using Poetry..."
    cyclonedx-py poetry > sbom-python-poetry.json
fi 

if [ -f "requirements.txt" ]; then
    echo "Detected requirements.txt. Generating SBOM using pip..."
    cyclonedx-py requirements > sbom-python-pip.json
fi

echo "Done"

# For each sbom*.json file, scan it with Grype
for sbom in ./sbom*.json; do
    if [ -s "$sbom" ]; then
        echo "$sbom file exists and has data. Scanning with Grype..."
        grype "sbom:$sbom" -o json > "$(basename "$sbom" .json)-analysis.json"
        echo "Done"
    fi
done

# Initialize an error flag
error_occurred=false

# Then compare to ignored issues
for analysis in ./sbom*-analysis.json; do
    if [ -s "$analysis" ]; then
        echo "$analysis file exists and has data. Comparing to ignored issues..."
        
        # Check the exit status of the last command
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
    exit 0
fi