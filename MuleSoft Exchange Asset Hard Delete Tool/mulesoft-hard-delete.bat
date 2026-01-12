@echo off
REM Wrapper for mulesoft-hard-delete.ps1
powershell -ExecutionPolicy Bypass -File "%~dp0mulesoft-hard-delete.ps1" %*
