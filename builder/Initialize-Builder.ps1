# Install roles
Install-WindowsFeature -Name Hyper-V -IncludeManagementTools
Install-WindowsFeature -Name DHCP -IncludeManagementTools

# Install chocolatey
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install tools
choco install -y packer azcopy10 git
