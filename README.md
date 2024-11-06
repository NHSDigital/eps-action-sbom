# EPS SBOM scanning action

[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=NHSDigital_eps-action-sbom&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=NHSDigital_eps-action-sbom)

This workflow generates a Software Bill Of Materials (SBOM) for Python and NPM in a project. It also scans these for security vulnerabilities, and reports an error if any are found. Reports are uploaded as artifacts.

Under the hood, it uses `syft`. The repository's devcontainer is built, the project is installed, and `syft` then scans the whole container to produce a series of SBOM. These are then scanned with `grype`.

Specific vulnerabilities can be ignored for a repository by adding the issue ID to an ignore file in the relevant repository: `ignored_security_issues.json`, e.g.
```
[
  {
    "vulnerability_id": "GHSA-4jcv-vp96-94xr",
    "reason": "The fix for this vulnerability is planned for the next sprint"
  }
]
```

This must be in the root of the project.

## Requirements

When used as part of a Github workflow, this action assumes that the workflow has already installed the target project, for example having run a `make install` command. The docker container that the action is being run inside of will be scanned to produce the SBOM.

## Secrets

### `GITHUB_TOKEN`

Some `npm` packages require a github token to access a private repository. This token is assumed to be supplied as a secret, keyed as `GITHUB_TOKEN`. Github should add this automatically.

## Outputs

None

## Example usage

Simply call the job in a workflow file, after the project is built. For example,

```
name: SBOM scan PR

on:
  pull_request:
    branches: [main]

jobs:
  create_sbom:
    runs-on: ubuntu-latest
    steps:
      build_project:
        run: |
          make install 

      sbom_scans:
        uses: NHSDigital/eps-action-sbom/.github/workflows/sbom_workflow.yml@<VERSION TAG>
```
