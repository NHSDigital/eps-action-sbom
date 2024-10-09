.PHONY: install build test publish release submodule_update check-licenses

test:
	bats test/test.bats

lint:
	shellcheck *.sh

clean:
	find test -type d -name 'node_modules' -exec rm -rf {} \;
	find test -type f -name 'sbom*' -exec rm -f {} \;
	find test -type f -name '.tool-versions' -exec rm -f {} \;
