setup_file() {

    load "setup.bash"
    # shellcheck disable=SC2329
    bats::on_failure() {
        echo "Test failed. Collecting debug information..."
        echo "${output}"
    }
}

# put any teardown code here
# teardown() {
# }

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'
    load 'test_helper/bats-file/load'
}

# bats test_tags=no_content
@test "No content allows SBOM to execute" {
    TEST_DIRECTORY=".test_run/no-issues/no-content"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -
    assert_success
}

# bats test_tags=issue_free, npm
@test "Can generate an issue-free SBOM for NPM" {
    TEST_DIRECTORY=".test_run/no-issues/npm-only"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_file_exist ${TEST_DIRECTORY}/sbom-npm.json

    # No python files should be made
    assert_file_not_exist ${TEST_DIRECTORY}/sbom-python.json
}

# bats test_tags=issue_free, python
@test "Can generate an issue-free SBOM for Pip" {
    TEST_DIRECTORY=".test_run/no-issues/python-pip-only"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_file_exist ${TEST_DIRECTORY}/sbom-python.json

    assert_file_not_exist ${TEST_DIRECTORY}/sbom-npm.json
}

# bats test_tags=issue_free, python
@test "Can generate an issue-free SBOM for Poetry" {
    TEST_DIRECTORY=".test_run/no-issues/python-poetry-only"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_file_exist ${TEST_DIRECTORY}/sbom-python.json
    
    assert_file_not_exist ${TEST_DIRECTORY}/sbom-npm.json
}

# bats test_tags=issue_free, python, npm
@test "Can generate issue-free SBOM for NPM and Pip" {
    TEST_DIRECTORY=".test_run/no-issues/npm-plus-pip"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_file_exist ${TEST_DIRECTORY}/sbom-python.json
    assert_file_exist ${TEST_DIRECTORY}/sbom-npm.json
}

# bats test_tags=issue_free, python, npm
@test "Can generate issue-free SBOM for NPM and poetry" {
    TEST_DIRECTORY=".test_run/no-issues/npm-plus-poetry"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    run docker run -i --rm -v ${LOCAL_WORKSPACE_FOLDER}/test/no-issues/npm-plus-poetry:/working eps-sbom

    assert_file_exist ${TEST_DIRECTORY}/sbom-python.json
    assert_file_exist ${TEST_DIRECTORY}/sbom-npm.json
}

# bats test_tags=issue_free, golang
@test "Can generate issue-free SBOM for golang" {
    TEST_DIRECTORY=".test_run/no-issues/golang"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_file_exist ${TEST_DIRECTORY}/sbom-golang.json

    assert_file_not_exist ${TEST_DIRECTORY}/sbom-python.json
    assert_file_not_exist ${TEST_DIRECTORY}/sbom-npm.json
}

# bats test_tags=issue, golang
@test "Fails when a known golang threat is encountered" {
    TEST_DIRECTORY=".test_run/issues/golang"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_failure
    assert_output --partial "GHSA-p744-4q6p-hvc2"
    assert_output --partial "GHSA-66p8-j459-rq63"
    assert_output --partial "GHSA-494h-9924-xww9"
}

# bats test_tags=issue, npm
@test "Fails when a known NPM threat is encountered" {
    TEST_DIRECTORY=".test_run/issues/npm-only"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_failure
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
}

# bats test_tags=ignored, npm
@test "Passes when an ignored issues is encountered - npm" {
    TEST_DIRECTORY=".test_run/issues/ignore-npm-issue"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_success
    assert_output --partial "GHSA-8rmg-jf7p-4p22"
    assert_output --partial "This is a test to see if ignoring the issue works"
}

# bats test_tags=issue, python
@test "Fails when a known python pip threat is encountered" {
    TEST_DIRECTORY=".test_run/issues/python-pip-only"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_failure

    assert_output --partial "GHSA-5p8v-58qm-c7fp"
}

# bats test_tags=ignored, python
@test "Passes when an ignored issue is encountered - python pip" {
    TEST_DIRECTORY=".test_run/issues/ignore-pip-issue"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_success
    assert_output --partial "GHSA-5p8v-58qm-c7fp"
    assert_output --partial "This is a test to see if ignoring the issue works"
}

# bats test_tags=issue, python
@test "Fails when a known python poetry threat is encountered" {
    TEST_DIRECTORY=".test_run/issues/python-poetry-only"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_failure

    assert_output --partial "GHSA-9298-4cf8-g4wj"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
}

# bats test_tags=issue, python
@test "Passes when an ignored issue is encountered - python poetry" {
    TEST_DIRECTORY=".test_run/issues/ignore-poetry-issue"
    cp entrypoint.sh ${TEST_DIRECTORY}/entrypoint.sh

    cd ${TEST_DIRECTORY}
    run ./entrypoint.sh
    cd -

    assert_failure
    assert_output --partial "GHSA-4jcv-vp96-94xr"
    assert_output --partial "This is a test to see if ignoring the issue works"
    assert_output --partial "GHSA-5wvp-7f3h-6wmm"
    assert_output --partial "This is a second ignored issue"
}

