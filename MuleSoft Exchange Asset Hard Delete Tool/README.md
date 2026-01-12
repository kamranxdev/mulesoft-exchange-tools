# MuleSoft Exchange Asset Hard Delete Tool

This tool allows you to hard delete assets from MuleSoft Exchange. It includes scripts for both PowerShell and Bash.

## Scripts

*   `mulesoft-hard-delete.ps1`: PowerShell script for Windows users.
*   `mulesoft-hard-delete.sh`: Bash script for Linux/macOS users.

## Usage

### Prerequisites

*   You must have the necessary permissions to delete assets in MuleSoft Exchange.
*   Relevant API credentials (client ID, client secret, etc.) may be required.

### Options

Both scripts support the following options:

*   Username (`-u` / `-Username`): MuleSoft username.
*   Password (`-p` / `-Password`): MuleSoft password.
*   Org ID (`-o` / `-OrgId`): Organization ID.
*   Limit (`-l` / `-Limit`): Number of assets to list (default: 40).
*   Offset (`-Offset`): Offset for pagination (default: 0).
*   Search (`-s` / `-Search`): Search term to filter assets.

### Windows (PowerShell / Batch)

You can run the tool directly via PowerShell.

**Using PowerShell:**
```powershell
./mulesoft-hard-delete.ps1 -Username <USERNAME> -Password <PASSWORD> -OrgId <ORG_ID>
```

### Linux / macOS (Bash)

```bash
chmod +x mulesoft-hard-delete.sh
./mulesoft-hard-delete.sh -u <USERNAME> -p <PASSWORD> -o <ORG_ID>
```

Example with optional parameters:
```bash
./mulesoft-hard-delete.sh -u myuser -p mypass -o myorg -l 10 -s "my-api"
```

Please refer to the script comments or run with help flags (if available) for detailed parameter information.
