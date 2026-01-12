# Anypoint VPC & DLB Audit Tool

## Problem
Configuration details for Dedicated Load Balancers (DLBs) and Virtual Private Clouds (VPCs), such as firewall rules, mapping rules, and certificates, are often hidden deep within the Anypoint Platform UI. Comparing rules between two DLBs or auditing the network configuration for security compliance is visually impossible and error-prone.

## Aim
This tool aims to provide deep visibility into network infrastructure by:
1.  Pulling the full configuration of all DLBs and VPCs.
2.  Exporting details (Firewall rules, mappings, certificates) as JSON/YAML.
3.  Enabling easy comparison for network troubleshooting and configuration drift detection.

## Usage

### Windows (PowerShell)

```powershell
.\vpc_dlb_audit.ps1 -Username <USERNAME> -Password <PASSWORD> -OrgId <ORG_ID> [-OutputFile <FILE>]
```

### Linux / macOS (Bash)

```bash
chmod +x vpc_dlb_audit.sh
./vpc_dlb_audit.sh --username <USERNAME> --password <PASSWORD> --org_id <ORG_ID> [--output <FILE>]
```
