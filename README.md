# EPS SBOM scanning action

This workflow generates a Software Bill Of Materials (SBOM) for Python and NPM in a project. It also scans these for security vulnerabilities, and reports an error if any are found. Reports are uploaded as artifacts.

Under the hood, it uses `syft`. The repository's devcontainer is built, the project is installed, and `syft` then scans the whole container to produce a series of SBOM. These are then scanned with `grype`.

Specific vulnerabilities can be ignored for a repository by adding the issue ID to an ignore file in the relevant repository: `ignored_security_issues.json`, e.g.
```
[
	"GHSA-4jcv-vp96-94xr"
]
```

This must be in the root of the project.

## Secrets

### `GITHUB_TOKEN`

Some `npm` packages require a github token to access a private repository. This token is assumed to be supplied as a secret, keyed as `GITHUB_TOKEN`

## Outputs

None

## Example usage

Simply call the job in a workflow file. For example,

```
name: SBOM scan PR

on:
  pull_request:
    branches: [main]

jobs:
  sbom_scans:
    uses: NHSDigital/eps-action-sbom/.github/workflows/sbom_workflow.yml@v2.0.0
```
