# EPS SBOM scanning action

This action generates a Software Bill Of Materials (SBOM) for Python and NPM in a project. It also scans these for security vulnerabilities, and reports an error if any are found. For python, both `requirements.txt` and Poetry installations are supported.

Specific vulnerabilities can be ignored by adding their ID to the ignore file in this repository: `ignored_security_issues.json`, e.g.
```
[
	"GHSA-4jcv-vp96-94xr"
]
```

## Inputs

### "node_version"

Used to specify the version of nodeJS used in your project. Versions are mutually incompatible, so a project built with node 18 cannot be analysed using node 20, for example. Allowed versions are `["18", "20", "22"]`. Defaults to "20".

## Outputs

None

## Example usage

```
- name: Create and scan SBOM
  uses: NHSDigital/eps-action-sbom@v1
  with:
	node_version: "20"
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
In addition, if you are using a dev container, it must have the docker-in-docker feature installed. This is added to the `devcontainer.json` features field:
```
    "features": {
      "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {
        "version": "latest",
        "moby": "true",
        "installDockerBuildx": "true"
      }
    },
```
