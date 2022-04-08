netsh.exe winhttp reset proxy
Write-Output "Set the power profile to high performance" 
powercfg.exe /setactive SCHEME_MIN

Write-Output "Enable RDP:"
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0 -Type DWord -Force

Write-Output "Seting RDP port 3389:" 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name PortNumber -Value 3389 -Type DWord -Force

Write-Output "Listening on every network interface:" 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name LanAdapter -Value 0 -Type DWord -Force

Write-Output "Configuring network-level authentication (NLA) mode for the RDP connections" 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1 -Type DWord -Force

Write-Output "Setting the keep-alive value" 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name KeepAliveTimeout -Value 1 -Type DWord -Force

Write-Output "Setting the reconnect options:" 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name fInheritReconnectSame -Value 1 -Type DWord -Force
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name fReconnectSame -Value 0 -Type DWord -Force

Write-Output "Limiting the number of concurrent connections:" 
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\Winstations\RDP-Tcp' -Name MaxInstanceCount -Value 4294967295 -Type DWord -Force

Write-Output "Configuring firewall rules" 

Write-Output "Turning on Windows Firewall on the three profiles (domain, standard, and public)" 
Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True

Write-Output "Allowing WinRM through the three firewall profiles (domain, private, and public), and enable the PowerShell remote service" 
Enable-PSRemoting -Force
Set-NetFirewallRule -Name WINRM-HTTP-In-TCP, WINRM-HTTP-In-TCP-PUBLIC -Enabled True

Write-Output "Allowing the RDP traffic" 
Set-NetFirewallRule -Group '@FirewallAPI.dll,-28752' -Enabled True

Write-Output "Enabling the rule for file and printer sharing so the VM can respond to ping requests inside the virtual network" 
Set-NetFirewallRule -Name FPS-ICMP4-ERQ-In -Enabled True

Write-Output "Creating Rule for the Azure platform network" 
New-NetFirewallRule -DisplayName AzurePlatform -Direction Inbound -RemoteAddress 168.63.129.16 -Profile Any -Action Allow -EdgeTraversalPolicy Allow
New-NetFirewallRule -DisplayName AzurePlatform -Direction Outbound -RemoteAddress 168.63.129.16 -Profile Any -Action Allow

Write-Output "Setting boot config" 
bcdedit.exe /set "{bootmgr}" integrityservices enable
bcdedit.exe /set "{default}" device partition=C:
bcdedit.exe /set "{default}" integrityservices enable
bcdedit.exe /set "{default}" recoveryenabled Off
bcdedit.exe /set "{default}" osdevice partition=C:
bcdedit.exe /set "{default}" bootstatuspolicy IgnoreAllFailures
bcdedit.exe /set "{bootmgr}" displaybootmenu yes
bcdedit.exe /set "{bootmgr}" timeout 5
bcdedit.exe /set "{bootmgr}" bootems yes
bcdedit.exe /ems "{current}" ON
bcdedit.exe /emssettings EMSPORT:1 EMSBAUDRATE:115200

Write-Output "Done: setup.ps1" 