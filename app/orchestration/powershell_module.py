"""
PowerShell Orchestration Module
"""
import subprocess

def run_powershell_command(command):
    cmd = ["pwsh", "-Command", command]
    result = subprocess.run(cmd, capture_output=True, text=True)
    return {"stdout": result.stdout, "stderr": result.stderr, "returncode": result.returncode}
