# EPS cfn-lint action

This action runs cfn-lint for all yaml files under cloudformation or SAMtemplates folders.   
If errors are found then it exits with an error

## Inputs

None

## Outputs

None

## Example usage

```
      - name: Run cfn lint
        uses: anthony-nhs/poc-cfn-lint@main
```