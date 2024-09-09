# EPS cfn-lint action

This action generates a Software Bill Of Materials (SBOM) for Python and NPM in a project. It also scans these for security vulnerabilities, and reports an error if any are found.

Specific vulnerabilities can be ignored by adding their ID to the ignore file in this repository: `ignored_security_issues.json`.

## Inputs

None

## Outputs

None

## Example usage

```
      - name: Create and scan SBOM
        uses: NHSDigital/eps-action-sbom@v1
```

This can be used as a `makefile` target like so:
```
sbom:
	mkdir -p ~/git_actions
	git -C ~/git_actions/eps-actions-sbom/ pull || git clone https://github.com/NHSDigital/eps-action-sbom.git ~/git_actions/eps-actions-sbom/
	docker build -t eps-sbom -f ~/git_actions/eps-actions-sbom/Dockerfile ~/git_actions/eps-actions-sbom/
	docker run -it --rm -v $${LOCAL_WORKSPACE_FOLDER:-.}:/github/workspace eps-sbom
```
Note that this requires the `LOCAL_WORKSPACE_FOLDER` environment variable to be set. In VS Code dev containers, this can be added to the `devcontainer.json` file:
```
  "remoteEnv": { "LOCAL_WORKSPACE_FOLDER": "${localWorkspaceFolder}" },
```
