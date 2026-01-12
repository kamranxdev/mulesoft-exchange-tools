# Exchange Asset Dependency "Ghost Hunter"

## Problem
Over time, MuleSoft Exchange accumulates a large number of assets (API Fragments, Connectors, Examples) that are no longer used by any active API or application. These "orphaned" assets clutter the repository, making it hard to find relevant assets and maintaining technical debt. Identifying which assets have zero consumers manually is not feasible.

## Aim
This tool aims to clean up the Exchange repository by:
1.  Analyzing the dependency tree of all assets.
2.  Identifying "Orphaned" assets (those with 0 consumers).
3.  Recommending these assets for archiving or deletion.

## Usage

### Windows (PowerShell)

```powershell
# Using the wrapper script
.\ghost_hunter.ps1 --username <USER> --password <PASS> --org_id <ORG_ID>

# Or directly with Python
python ghost_hunter.py --username <USER> --password <PASS> --org_id <ORG_ID>
```

### Linux / macOS (Bash)

```bash
chmod +x ghost_hunter.py
./ghost_hunter.py --username <USER> --password <PASS> --org_id <ORG_ID>
```
