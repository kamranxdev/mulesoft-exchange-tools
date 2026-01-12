# MuleSoft Business Group User/Role Auditor

## Problem
In the Anypoint Platform, identifying "Who has Admin access?" or auditing user permissions across a complex organization structure with multiple Business Groups and Environments is extremely difficult. Administrators often have to manually click through each Business Group and Environment in the UI to view user roles, which is time-consuming and error-prone.

## Aim
This tool aims to automate the security audit process by:
1.  Recursively walking through the entire Organization tree (Root + all Children).
2.  Fetching all users and their assigned permissions/roles for each context.
3.  Exporting a comprehensive flat CSV report.

## Usage

### Windows (PowerShell)

```powershell
.\audit_users.ps1 -Username <user> -Password <pass> [-ClientId <id> -ClientSecret <secret>] [-OrgId <id>] [-OutputFile <file>]
```

### Linux / macOS (Bash)

```bash
chmod +x audit_users.sh
./audit_users.sh --username <user> --password <pass> [--client_id <id> --client_secret <secret>] [--org_id <id>] [--output <file>]
```
