"""
Bash Orchestration Module
"""
import subprocess

def run_bash_command(command):
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    return {"stdout": result.stdout, "stderr": result.stderr, "returncode": result.returncode}
