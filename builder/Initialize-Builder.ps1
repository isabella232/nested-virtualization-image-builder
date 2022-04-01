$ErrorActionPreference = "Stop"

# Install roles
Install-WindowsFeature -Name Hyper-V, DHCP -IncludeManagementTools

# Install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools via chocolatey
$env:PATH += "C:\ProgramData\chocolatey\bin;"
choco install -y packer azcopy10 git azure-cli
