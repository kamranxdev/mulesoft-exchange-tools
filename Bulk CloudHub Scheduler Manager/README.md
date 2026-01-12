# Bulk CloudHub Scheduler Manager

## Problem
Managing runtime schedules for a large number of applications (50+) in non-production environments (Dev/Test) is tedious. Administrators often want to stop schedules or applications at night to save vCores and reduce costs, but doing this one by one in the Runtime Manager UI is inefficient.

## Aim
This tool aims to provide a "Night Sentry" capability to:
1.  Bulk Start/Stop schedules or Applications.
2.  Filter targets based on name patterns (e.g., `*-dev`) or Environment IDs.
3.  Facilitate cost optimization and environment resets.

## Usage

### Windows (PowerShell)

```powershell
.\scheduler_manager.ps1 -Username <user> -Password <pass> -EnvId <id> -Action <START|STOP> -Pattern <regex> [-DryRun]
```

### Linux / macOS (Bash)

```bash
chmod +x scheduler_manager.sh
./scheduler_manager.sh --username <user> --password <pass> --env_id <id> --action <START|STOP> --pattern <regex> [--dry-run]
```
