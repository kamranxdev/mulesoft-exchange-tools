# MuleSoft Ops Toolkit

**Formerly:** `mulesoft-exchange-tools`

This repository contains a comprehensive collection of utility scripts and automation tools designed to simplify operations, security audits, and asset management for the Anypoint Platform.

## Available Tools

| Tool | Description | Links |
| :--- | :--- | :--- |
| **Anypoint VPC & DLB Audit Tool** | Deep audit of VPCs and DLBs to export firewall rules, mappings, and certificates for security compliance. | [Read More](./Anypoint%20VPC%20DLB%20Audit%20Tool/README.md) |
| **Bulk CloudHub Scheduler Manager** | "Night Sentry" utility to bulk start/stop schedules and applications for cost savings in non-prod environments. | [Read More](./Bulk%20CloudHub%20Scheduler%20Manager/README.md) |
| **Deployment Property Validator** | Pre-deployment check to ensure all `${placeholders}` in code have matching values in your properties file or CloudHub. | [Read More](./Deployment%20Property%20Validator/README.md) |
| **Exchange Asset Dependency Ghost Hunter** | Analyzes Exchange assets to find "orphaned" dependencies with zero consumers for cleanup. | [Read More](./Exchange%20Asset%20Dependency%20Ghost%20Hunter/README.md) |
| **MuleSoft Business Group User Role Auditor** | Recursively audits the entire organization tree to export a flat CSV of all users and their permissions. | [Read More](./MuleSoft%20Business%20Group%20User%20Role%20Auditor/README.md) |
| **MuleSoft Exchange Asset Hard Delete Tool** | Command-line utility to permanently "hard delete" assets from Exchange. | [Read More](./MuleSoft%20Exchange%20Asset%20Hard%20Delete%20Tool/README.md) |
| **Secure Property Tool Wrapper** | Simple shell/PowerShell wrapper to make encrypting/decrypting secure properties easier. | [Read More](./Secure%20Property%20Tool%20Wrapper/README.md) |

## Getting Started

Each tool is contained within its own directory and includes specific instructions for usage on **Windows (PowerShell)** and **Linux/macOS (Bash)**.

Please browse the table above and click "Read More" to navigate to the specific tool you need.

## Prerequisites

Most tools in this repository require:
*   **Anypoint Platform Credentials** (Username/Password or Connected App)
*   **Python 3.x** or **PowerShell 7+** depending on the script.
*   **[MuleSoft Anypoint CLI](https://docs.mulesoft.com/anypoint-cli/)** (for some tools)

Check individual READMEs for detailed requirements.
