# Secure Property Tool Wrapper

## Problem
Using MuleSoft's standard "Secure Properties Tool" (the Java jar) requires remembering complex syntax with multiple flags (`-Dnode_id... java -jar ... string encrypt ...`). This often leads to syntax errors and frustration for developers who just want to quickly encrypt a password.

## Aim
This tool aims to simplify the encryption/decryption workflow by:
1.  Providing a simple shell wrapper.
2.  Allowing commands like `./secure_prop.sh encrypt "myPassword"`
3.  Handling the Java execution complexity behind the scenes.

## Usage

### Windows (PowerShell)

```powershell
.\secure_prop.ps1 -Action encrypt -Key "mykey" -Value "mysecret" [-Algorithm Blowfish] [-Mode CBC]
```

### Linux / macOS (Bash)

```bash
chmod +x secure_prop.sh
./secure_prop.sh encrypt "mykey" "mysecret" [Blowfish] [CBC]
```
