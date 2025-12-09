# Windows Service Installation Script
$serviceName = "OllamaPipeline"
$pythonPath = "python.exe"
$scriptPath = "$PSScriptRoot\..\daemon.py"

if (!(Get-Command nssm -ErrorAction SilentlyContinue)) {
    Write-Host "Install NSSM from: https://nssm.cc/"
    exit 1
}

nssm install $serviceName $pythonPath $scriptPath
nssm set $serviceName AppDirectory "$PSScriptRoot\.."
nssm set $serviceName DisplayName "Ollama Pipeline"

Write-Host "Service installed: $serviceName"
