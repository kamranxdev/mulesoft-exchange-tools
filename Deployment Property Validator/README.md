# Deployment Property Validator

## Problem
Deployment failures often occur because of mismatched properties. A specific property might be defined in the code's `config.yaml` using a placeholder like `${https.port}`, but the actual value is missing from the CloudHub 'Properties' tab or the `secure-properties` file. Resolving these "Deployment Failed" errors requires tedious manual cross-referencing.

## Aim
This tool aims to ensure zero-failure deployments by:
1.  Scanning the project code for all property placeholders `${...}`.
2.  Comparing them against a provided list of properties (from a file or API export).
3.  Reporting any missing or extra properties before the deployment starts.

## Usage

### Windows (PowerShell)

```powershell
.\validate_props.ps1 -Project "C:\path\to\project" -Properties "C:\path\to\dev.yaml"
```

### Linux / macOS (Bash)

```bash
chmod +x validate_props.sh
./validate_props.sh --project /path/to/project --properties /path/to/dev.yaml
```
