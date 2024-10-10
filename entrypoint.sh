#!/bin/sh -l

set -e


# Remove any existing SBOMs
rm -f ./sbom*.json

# Get the .tool-versions for the correct node
NODE_VERSION=${1:-'20'}
cp /node_versions/node"${NODE_VERSION}"/.tool-versions .

# If the current github workflow has installed asdf, it will pass the ASDF_DIR and ASDF_DATA_DIR
# environment variables in to the action, overriding this docker container's installation and leaving it
# unable to find the scripts.
# Here, we check if these variables are set, and if necessary we copy in our local installation of asdf.
if [ -n "${ASDF_DIR}" ]; then
    echo "ASDF_DIR not set. Copying in local installation of asdf..."
    mkdir -p "${ASDF_DIR}"
    cp -r /root/.asdf/* "${ASDF_DIR}"/
fi
asdf reshim

# Scan the dependencies for NPM
if [ -f "package.json" ] && [ -f "package-lock.json" ]; then
    echo "Generating SBOM for Node.js..."
    # The node_modules directory is needed for generating the SBOM
    asdf exec npm install
    asdf exec cyclonedx-npm --output-format json --output-file sbom-node.json
    echo "Done"
else
    echo "package.json and package-lock.json not found. Cannot generate Node.js SBOM."
fi

# Repeat the above steps for Python
# Check if pyproject.toml (Poetry) or requirements.txt exists
if [ -f "pyproject.toml" ]; then
    echo "Detected Poetry project. Generating SBOM using Poetry..."
    asdf exec cyclonedx-py poetry > sbom-python-poetry.json
fi 

if [ -f "requirements.txt" ]; then
    echo "Detected requirements.txt. Generating SBOM using pip..."
    asdf exec cyclonedx-py requirements > sbom-python-pip.json
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

# Don't exit on failure until we check all files.
set +e
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
fi
