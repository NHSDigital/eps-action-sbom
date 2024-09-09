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