#Requires -RunAsAdministrator
Set-PSDebug -Trace 0

Write-Output 'Downloading and installing DeviceProxy'

if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output 'Powershell needs to be version 3 or greater'
    exit 1
}

$server = $args[0]
$hardware = $args[1]
$installation = $args[2]
$installationType = $args[3]

Switch ($server)
{
    'Staging' {}
    'Production' {}
    default
    {
        Write-Output 'server needs to be specified Production | Staging'
        exit 1
    }
}
$server = 'Windows' + $server

Switch ($hardware)
{
    'DPEMS-V1' {}
    'DPEMS-V1_DBV2' {}
    'DPEMS-V1_DBV3' {}
    'DPEMS-V1_FANEXT' {}
    'DPEMS-V2' {}
    default
    {
        Write-Output 'hardware needs to be specified DPEMS-V1 | DPEMS-V1_DBV2 | DPEMS-V1_DBV3 | DPEMS-V1_FANEXT | DPEMS-V2'
        exit 1
    }
}
$environment = $server + '_' + $hardware

if (!$installation)
{
    Write-Output 'Installation must be specified new | old_installation_folder'
    exit
}

Switch ($installationType)
{
    'singlePC' {}
    'dualPC' {}
    default
    {
        Write-Output 'Installation Type must be specified singlePC | dualPC'
        exit 1
    }
}

if ($installation -ne 'new')
{
    $settingFile = "$installation\conf\setting.json"
    $dataFile = "$installation\data\data.json"
    if ($(Test-Path -Path $settingFile) -ne $true)
    {
        Write-Output "setting.json does not exist in old Installation folder $settingFile"
        exit
    }
    if ($(Test-Path -Path $dataFile) -ne $true)
    {
        Write-Output "data.json does not exist in old Installation folder $installation\..\data\data.json"
        exit
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

# Set up the IP Address for the secondard Ethernet port for a Dual PC setup
if ($installationType -eq 'dualPC')
{
    $newIPAddress = '192.168.64.1'
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

$env:SCOOP = 'C:\scoop'
[environment]::setEnvironmentVariable('SCOOP', $env:SCOOP, 'User')

try
{
    scoop info | Out-Null
}
catch
{
    Write-Output 'Installing Scoop package management system...'

    Invoke-Expression "& {$(Invoke-RestMethod get.scoop.sh)} -RunAsAdmin"
    #Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}

scoop update

$installedApps = $(scoop list)
$gitInstalled = $($installedApps | Select-String -Pattern 'git' -CaseSensitive -SimpleMatch)
if (!$gitInstalled)
{
    scoop install git
}

scoop bucket add scoop-dev https://github.com/Design2Production/scoop-dev.git

$sermanInstalled = $($installedApps | Select-String -Pattern 'serman' -CaseSensitive -SimpleMatch)
$deviceProxyInstalled = $($installedApps | Select-String -Pattern 'DeviceProxy' -CaseSensitive -SimpleMatch)
if (!$sermanInstalled)
{
    scoop install serman
}
if (!$deviceProxyInstalled)
{
    scoop install DeviceProxy
}

#create data folders
Write-Output 'Create ProgramData directories...'
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\cache\firmware | Out-Null
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\data | Out-Null
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\log | Out-Null

Write-Output 'Copy data files...'
$deviceProxyDirectory = $(scoop prefix DeviceProxy)
if ($installation -eq 'new')
{
    #copy settings files from applicaiton and open for editing
    Copy-Item "$deviceProxyDirectory\setting.json" -Destination 'C:\ProgramData\DP\DeviceProxy\setting.json'
    Write-Output 'Editing setting.json in Notepad - Save file and exit Notepad to continue...'
    notepad.exe C:\ProgramData\DP\DeviceProxy\setting.json | Out-Null
    Write-Output 'setting.json saved'
    Write-Output 'Editing data.json in Notepad - Save file and exit Notepad to continue...'
    Copy-Item "$deviceProxyDirectory\data.json" -Destination 'C:\ProgramData\DP\DeviceProxy\data\data.json'
    notepad.exe C:\ProgramData\DP\DeviceProxy\data\data.json | Out-Null
    Write-Output 'data.json saved'
}
else
{
    #copy settings files from old installation
    Copy-Item $settingFile -Destination 'C:\ProgramData\DP\DeviceProxy\setting.json'
    Copy-Item $dataFile -Destination 'C:\ProgramData\DP\DeviceProxy\data\data.json'
}

# Add auto update to scheduler
Write-Output 'Add task for Autoupdate...'
$taskName = 'DPUpdateDeviceProxy'
$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $taskName }
if ($taskExists)
{
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:$false 2>$null
}
$action = New-ScheduledTaskAction -Execute 'C:\scoop\apps\DeviceProxy\current\DPUpdateDeviceProxy.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId 'NT AUTHORITY\SYSTEM' -LogonType ServiceAccount -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -MultipleInstances Parallel
Register-ScheduledTask -TaskName $taskName -TaskPath '\DP\' -Action $action -Trigger $trigger -Settings $settings -Principal $principal

# Add DeviceProxy as Windows Service
$deviceProxyXml = $deviceProxyDirectory + '\DeviceProxy.xml'
Write-Output 'Stop DeviceProxy Service...'
Stop-Service DeviceProxy 2>$null

$sermanFolder = 'C:\serman'
if ($(Test-Path -Path $sermanFolder) -eq $true)
{
    Write-Output 'Uninstall DeviceProxy...'
    serman uninstall DeviceProxy 2>$null | Out-Null
    
    Write-Output 'Remove serman cache...'
    Remove-Item C:\serman -Recurse -Force 2>$null
}

Write-Output 'Install DeviceProxy service'
serman install $deviceProxyXml ASP_ENV=$environment --overwrite

Write-Output 'DeviceProxy installation complete'
