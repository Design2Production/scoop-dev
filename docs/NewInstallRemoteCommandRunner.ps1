#Requires -RunAsAdministrator
Set-PSDebug -Trace 0

$repo = 'scoop-dev'
$dpemsType = $args[0]

Write-Output 'Downloading and installing RemoteCommandRunner'

if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output 'Powershell needs to be version 3 or greater'
    exit 1
}

Switch ($dpemsType)
{
    'DPEMS-V1' {}
    'DPEMS-V2' {}
    default
    {
        Write-Output 'DPEMS Type must be specified DPEMS-V1 | DPEMS-V2'
        exit 1
    }
}

# Open the firewall for pings
$firewallRuleName = 'ICMP Allow incoming V4 echo request'
$firewallRule = Get-NetFirewallRule -DisplayName "$firewallRuleName" 2>$null
if ($null -eq $firewallRule)
{
    Write-Output "Adding Firewall Rule '$firewallRuleName' ..."
    netsh advfirewall firewall add rule name="$firewallRuleName" protocol=icmpv4:8,any dir=in action=allow
}
else
{
    if ($firewallRule.Enabled -eq 'True')
    {
        Write-Output "Firewall Rule '$firewallRuleName' exists and is enabled."
    }
    else
    {
        Write-Output "Firewall Rule '$firewallRuleName' exists but is disabled - Enabling now..."
        Enable-NetFirewallRule -DisplayName $firewallRuleName
        $firewallRule = Get-NetFirewallRule -DisplayName "$firewallRuleName" 2>$null
        if ($firewallRule.Enabled -eq 'True')
        {
            Write-Output "Firewall Rule '$firewallRuleName' exists and is enabled."
        }
        else 
        {
            Write-Output "Firewall Rule '$firewallRuleName' exists but could not be enabled - please check and enable manually"
            exit 1
        }
    }
}

# Open the firewall for port 5002
$firewallRuleName = 'TCP Port 5002'
$firewallRule = Get-NetFirewallRule -DisplayName "$firewallRuleName" 2>$null
if ($null -eq $firewallRule)
{
    Write-Output "Adding Firewall Rule '$firewallRuleName' ..."
    netsh advfirewall firewall add rule name="$firewallRuleName" dir=in action=allow protocol=TCP localport=5002
}
else
{
    if ($firewallRule.Enabled -eq 'True')
    {
        Write-Output "Firewall Rule '$firewallRuleName' exists and is enabled."
    }
    else
    {
        Write-Output "Firewall Rule '$firewallRuleName' exists but is disabled - Enabling now..."
        Enable-NetFirewallRule -DisplayName $firewallRuleName
        $firewallRule = Get-NetFirewallRule -DisplayName "$firewallRuleName" 2>$null
        if ($firewallRule.Enabled -eq 'True')
        {
            Write-Output "Firewall Rule '$firewallRuleName' exists and is enabled."
        }
        else 
        {
            Write-Output "Firewall Rule '$firewallRuleName' exists but could not be enabled - please check and enable manually"
            exit 1
        }
    }
}

if ($dpemsType -eq 'DPEMS-V1')
{
    # Set up the IP Address for the secondard Ethernet port for the Dual PC setup for DPEMS-V1
    $newIPAddress = '192.168.64.2'
    $newSubnetMask = '255.255.255.0'
    $physicalAdapters = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -eq '802.3' }
    $manualAdapter = $null
    $dhcpAdapter = $null
    $wellknownAdapter = $null
    foreach ($physicalAdapter in $physicalAdapters)
    {
        $configurations = Get-NetIPAddress -InterfaceIndex $physicalAdapter.InterfaceIndex -AddressFamily IPv4
        foreach ($configuration in $configurations)
        {
            Write-Output "Detected $($configuration.InterfaceAlias) $($configuration.PrefixOrigin) $($configuration.IPAddress) $($configuration.AddressState)"
            switch ($configuration.AddressState)
            {
                'Invalid'
                {
                    Write-Output "Warning - Invalid IP Address has been detected on $($configuration.InterfaceAlias) - PLEASE CONFIGURE THE SECONDARY IP ADDRESSES MANUALLY"
                    exit 1
                }
                'Tentative'
                {
                    Write-Output "Warning - Tentative IP Address has been detected on $($configuration.InterfaceAlias) - PLEASE CONFIGURE THE SECONDARY IP ADDRESSES MANUALLY"
                    exit 1
                }
                'Duplicate'
                {
                    Write-Output "Warning - Duplicate IP Addresses have been detected on $($configuration.InterfaceAlias) - PLEASE CONFIGURE THE SECONDARY IP ADDRESSES MANUALLY"
                    exit 1
                }
                'Deprecated'
                {
                    continue
                }
                'Preferred'
                {
                    Out-Null
                }
            }
            if ($configuration.PrefixOrigin -eq 'Manual')
            {
                if ($null -eq $manualAdapter)
                {
                    $manualAdapter = $configuration
                }
                else
                {
                    Write-Output 'Both adapters are set to Manual - you will need to conifgure the network adapters manually'
                    exit 1
                }
            }
            elseif ($configuration.PrefixOrigin -eq 'Wellknown')
            {
                if ($null -eq $wellknownAdapter)
                {
                    $wellknownAdapter = $configuration
                }
                else
                {
                    Write-Output 'Both adapters are set to Wellknown - you will need to conifgure the network adapters manually'
                    exit 1
                }
            }
            elseif ($configuration.PrefixOrigin -eq 'Dhcp')
            {
                if ($null -eq $dhcpAdapter)
                {
                    $dhcpAdapter = $configuration
                }
                else
                {
                    Write-Output 'Both adapters are set to DHCP - you will need to conifgure the network adapters manually'
                    exit 1
                }
            }
        }
    }
    if (($null -eq $wellknownAdapter) -and ($null -eq $manualAdapter))
    {
        Write-Output 'The second Ethernet Adapter was not automatically identified - you will need to conifgure the network adapters manually'
        exit 1
    }
    $adapterToChange = $null
    if ($null -ne $dhcpAdapter)
    {
        if ($null -ne $manualAdapter)
        {
            $adapterToChange = $manualAdapter
        }
        elseif ($null -ne $wellknownAdapter)
        {
            $adapterToChange = $wellknownAdapter
        }
        else
        {
            Write-Output 'Could not automatically configure - you will need to conifgure the network adapters manually'
            exit 1
        }
    }
    else
    {
        Write-Output 'Could not automatically configure - you will need to conifgure the network adapters manually'
        exit 1
    }
    if ($null -ne $adapterToChange)
    {
        $interfaceIndex = $adapterToChange.InterfaceIndex
        Write-Output "Setting $($adapterToChange.InterfaceAlias) to $newIPAddress $newSubnetMask ..."
        # set the new ipaddress - we can use the powershell version of this, but the netsh call is actaully simpler to use...
        netsh interface ipv4 set address $interfaceIndex static $newIPAddress $newSubnetMask
        # give the network some time to go from tentative to preferred after we set it (technically we could use a do while here, but this is simpler and if it goes bad, it will need to be sorted manualy anyway)
        Start-Sleep 5
        $updatedConfigurations = Get-NetIPAddress -InterfaceIndex $interfaceIndex -AddressFamily IPv4
        Write-Output "DHCP $($dhcpAdapter.InterfaceAlias) $($dhcpAdapter.IPAddress)"
        foreach ($configuration in $updatedConfigurations)
        {
            Write-Output "Updated $($configuration.InterfaceAlias) $($configuration.PrefixOrigin) $($configuration.IPAddress) $($configuration.AddressState)"
            switch ($configuration.AddressState)
            {
                'Invalid'
                {
                    Write-Output "Warning - Invalid IP Address has been detected on $($configuration.InterfaceAlias) - PLEASE CONFIGURE THE SECONDARY IP ADDRESSES MANUALLY"
                }
                'Tentative'
                {
                    Write-Output "Warning - Tentative IP Address has been detected on $($configuration.InterfaceAlias) - PLEASE CONFIGURE THE SECONDARY IP ADDRESSES MANUALLY"
                }
                'Duplicate'
                {
                    Write-Output "Warning - Duplicate IP Addresses have been detected on $($configuration.InterfaceAlias) - PLEASE CONFIGURE THE SECONDARY IP ADDRESSES MANUALLY"
                }
                'Deprecated'
                {
                    Write-Output "Warning - Depricated IP Addresses have been detected on $($configuration.InterfaceAlias) - PLEASE CHECK THE SECONDARY IP ADDRESS ASSIGNMENT"
                }
                'Preferred'
                {
                    Out-Null
                }
            }
        }
    }
}
else
{
    $physicalAdapters = Get-NetAdapter -Physical | Where-Object { $_.PhysicalMediaType -eq '802.3' }
    foreach ($physicalAdapter in $physicalAdapters)
    {
        $configurations = Get-NetIPAddress -InterfaceIndex $physicalAdapter.InterfaceIndex -AddressFamily IPv4
        foreach ($configuration in $configurations)
        {
            Write-Output "Detected $($configuration.InterfaceAlias) $($configuration.PrefixOrigin) $($configuration.IPAddress) $($configuration.AddressState)"
        }
    }
}

$env:SCOOP = 'C:\scoop'
[environment]::setEnvironmentVariable('SCOOP', $env:SCOOP, 'User')

try
{
    scoop info | Out-Null
}
catch
{
    Write-Output 'Installing Scoop package management system...'

    Invoke-Expression "& { $(Invoke-RestMethod get.scoop.sh) } -RunAsAdmin"
}

#create .gitconfig file - to allow sync over slow internet connections
'[http]
postBuffer = 1048576000
[core]
packetGitLimit = 512m
packedGitWindowSize = 512m
compression = 0
[pack]
deltaCacheSize = 2047m
packSizeLimit = 2047m
windowMemory = 2047m
' | Out-File -Encoding ascii -NoNewline -FilePath $env:USERPROFILE\.gitconfig

scoop update

$installedApps = $(scoop list)
$gitInstalled = $($installedApps | Select-String -Pattern 'git' -CaseSensitive -SimpleMatch)
if (!$gitInstalled)
{
    scoop install git
}

scoop bucket add $repo https://github.com/Design2Production/$repo.git

$sermanInstalled = $($installedApps | Select-String -Pattern 'serman' -CaseSensitive -SimpleMatch)
$remoteCommandRunnerInstalled = $($installedApps | Select-String -Pattern 'RemoteCommandRunner' -CaseSensitive -SimpleMatch)
if (!$sermanInstalled)
{
    scoop install serman
}
if (!$remoteCommandRunnerInstalled)
{
    scoop install RemoteCommandRunner
}

$remoteCommandRunnerDirectory = $(scoop prefix RemoteCommandRunner)

# Add auto update to scheduler
Write-Output 'Add task for Autoupdate...'
$taskName = 'DPUpdateRemoteCommandRunner'
$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $taskName }
if ($taskExists)
{
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:$false 2>$null
}
$action = New-ScheduledTaskAction -Execute 'C:\scoop\apps\RemoteCommandRunner\current\DPUpdateRemoteCommandRunner.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
Register-ScheduledTask -TaskName $taskName -TaskPath '\DP\' -Action $action -Trigger $trigger -Settings $settings -Principal $principal

# Add RemoteCommandRunner as Windows Service
$remoteCommandRunnerXml = $remoteCommandRunnerDirectory + '\RemoteCommandRunner.xml'
Write-Output 'Stop RemoteCommandRunner Service...'
Stop-Service RemoteCommandRunner 2>$null

$sermanFolder = 'C:\serman'
if ($(Test-Path -Path $sermanFolder) -eq $true)
{
    Write-Output 'Uninstall RemoteCommandRunner...'
    serman uninstall RemoteCommandRunner 2>$null | Out-Null

    Write-Output 'Remove serman cache...'
    Remove-Item C:\serman -Recurse -Force 2>$null
}

Write-Output 'Install RemoteCommandRunner service'
serman install $remoteCommandRunnerXml --overwrite

Write-Output 'RemoteCommandRunner installation complete'

