.PHONY: install build test publish release submodule_update check-licenses

test:
	bats test/test.bats

lint:
	shellcheck *.sh

clean:
	find test/*issues/ -type d -name 'node_modules' -exec rm -rf {} \; 2>/dev/null
	find test/*issues/ -type f -name '*sbom*' -exec rm -f {} \; 2>/dev/null
	find test/*issues/ -type f -name '.tool-versions' -exec rm -f {} \; 2>/dev/null
	find test/*issues/ -type f -name 'Makefile' -exec rm -f {} \; 2>/dev/null
