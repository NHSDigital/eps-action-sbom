install:
	@if [ -f requirements.txt ]; then \
		echo "Installing Python dependencies from requirements.txt..."; \
		pip install -r requirements.txt --break-system-packages; \
	fi

	@if [ -f poetry.lock ] || [ -f pyproject.toml ]; then \
		echo "Installing Python project dependencies with Poetry..."; \
		poetry install; \
	fi

	@if [ -f package.json ]; then \
		echo "Installing npm dependencies..."; \
		npm install; \
	fi

.PHONY: install
