install:
	@if [ -f requirements.txt ]; then \
		echo "Installing Python dependencies from requirements.txt..."; \
		pip install -r requirements.txt; \
	fi

	@if [ -f poetry.lock ] || [ -f pyproject.toml ]; then \
		echo "Installing Python project dependencies with Poetry..."; \
		poetry install; \
	fi

	@if [ -f package.json ]; then \
		echo "Installing npm dependencies..."; \
		npm install; \
	fi

	@if [ -f go.mod ]; then \
		echo "Installing Go dependencies from go.mod..."; \
		go mod download; \
	elif [ -d vendor ]; then \
		echo "Go dependencies are vendored, no installation needed."; \
	elif ls *.go 1> /dev/null 2>&1; then \
		echo "Installing Go dependencies for non-module project..."; \
		go get ./...; \
	fi

	@if [ -f pom.xml ]; then \
		echo "Installing Java dependencies from pom.xml..."; \
		mvn install; \
	fi

.PHONY: install
