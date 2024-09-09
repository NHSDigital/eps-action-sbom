#!/bin/sh -l

# Check if the Node.js SBOM file exists. If it does, remove it and create a new one.
if [ -f "sbom-node.json" ]; then
    echo "Node.js SBOM file exists. Removing..."
    rm sbom-node.json
fi

# Scan the dependencies
echo "Generating SBOM for Node.js..."
cyclonedx-npm --output-format json --output-file sbom-node.json
echo "Done"

# Check that the Node.js SBOM file exists and has data in it
if [ -s "sbom-node.json" ]; then
    echo "Node.js SBOM file exists and has data. Scanning with Grype..."
    grype sbom:sbom-node.json -o json > node-sbom-analysis.json
    echo "Done"
else
    echo "Error: Node.js SBOM file does not exist or is empty."
    exit 1
fi

# Repeat the above steps for Python

# Check if the Python SBOM file exists. If it does, remove it and create a new one.
if [ -f "sbom-python.json" ]; then
    echo "Python SBOM file exists. Removing..."
    rm sbom-python.json
fi

echo "Generating SBOM for Python..."
cyclonedx-py poetry > sbom-python.json
echo "Done"

# Check that the Python SBOM file exists and has data in it
if [ -s "sbom-python.json" ]; then
    echo "Python SBOM file exists and has data. Scanning with Grype..."
    grype sbom:sbom-python.json -o json > python-sbom-analysis.json
    echo "Done"
else
    echo "Error: Python SBOM file does not exist or is empty."
    exit 1
fi

# Check raised NPM issues
/check-sbom-issues-against-ignores.sh /ignored_security_issues.json ./node-sbom-analysis.json

# Check raised Python issues
/check-sbom-issues-against-ignores.sh /ignored_security_issues.json ./python-sbom-analysis.json