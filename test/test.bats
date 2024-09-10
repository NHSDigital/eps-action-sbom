setup() {
    load '/usr/lib/bats/bats-support/load'
    load '/usr/lib/bats/bats-assert/load'
    docker build -t eps-sbom .

    # Remove all existing test output: *sbom*.json files
    rm -f test/**/*sbom*.json
    rm -rf test/**/node_modules
}

teardown() {
    rm -f test/**/*sbom*.json
    rm -rf test/**/node_modules
}

@test "No content allows SBOM to execute" {
    run docker run -i --rm -v ./test/no-issues/no-content:/github/workspace eps-sbom
    assert_success
}

@test "Can generate an issue-free SBOM for NPM" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-only:/github/workspace eps-sbom

    if [ ! -f "test/no-issues/npm-only/sbom-node.json" ]; then
        echo "Error: sbom-node.json file not found." >&2
        return 1
    fi

    # No python files should be made
    if [ -f "test/no-issues/npm-only/sbom-python*.json" ]; then
        echo "Error: sbom-python.json file should not be created." >&2
        return 1
    fi
}

@test "Can generate an issue-free SBOM for Pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-pip-only:/github/workspace eps-sbom

    if [ ! -f "test/no-issues/python-pip-only/sbom-python-pip.json" ]; then
        echo "Error: sbom-python-pip.json file not found." >&2
        return 1
    fi

    if [ -f "test/no-issues/python-pip-only/sbom-node.json" ]; then
        echo "Error: sbom-node.json file should not be created." >&2
        return 1
    fi

    if [ -f "test/no-issues/python-pip-only/sbom-python-poetry.json" ]; then
        echo "Error: sbom-python-poetry.json file should not be created." >&2
        return 1
    fi
}

@test "Can generate an issue-free SBOM for Poetry" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/python-poetry-only:/github/workspace eps-sbom

    if [ ! -f "test/no-issues/python-poetry-only/sbom-python-poetry.json" ]; then
        echo "Error: sbom-python.json file not found." >&2
        return 1
    fi
    
    if [ -f "test/no-issues/python-poetry-only/sbom-node.json" ]; then
        echo "Error: sbom-node.json file should not be created." >&2
        return 1
    fi
    
    if [ -f "test/no-issues/python-poetry-only/sbom-python-pip.json" ]; then
        echo "Error: sbom-python-pip.json file should not be created." >&2
        return 1
    fi
}

@test "Can generate issue-free SBOM for NPM and Pip" {
    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-plus-pip:/github/workspace eps-sbom
    
    if [ ! -f "test/no-issues/npm-plus-pip/sbom-python-pip.json" ]; then
        echo "Error: sbom-python.json file not found." >&2
        return 1
    fi

    if [ ! -f "test/no-issues/npm-plus-pip/sbom-node.json" ]; then
        echo "Error: sbom-node.json file file not found." >&2
        return 1
    fi

    if [ -f "test/no-issues/npm-plus-pip/sbom-python-poetry.json" ]; then
        echo "Error: sbom-python-poetry.json file should not be created." >&2
        return 1
    fi
}