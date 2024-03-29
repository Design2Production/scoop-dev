#Requires -RunAsAdministrator
Set-PSDebug -Trace 0

$repo = 'scoop-dev'

if ($repo -eq 'scoop-dev')
{
    Write-Output 'THIS IS A DEVELOPMENT VERSION OF THE DEVICE PROXY INSTALLER'
    Write-Output 'Are you sure you want to continue installation?'
    $answer = Read-Host -Prompt 'Type YES to continue'
    if ($answer -ne 'YES')
    {
        Write-Output 'Installation Aborted'
        exit 1
    }
}

Function SerialDisableDPEMSWatchDog
{
    # Disable the DPEMS watchdog using a network call so we don't get killed part way through the installation
    # The Proxy will enable the watchdog when it starts running

    $serialPortNames = [System.IO.Ports.SerialPort]::getportnames()
    $watchDogDisabled = $false
    
    foreach ($serialPortName in $serialPortNames)
    {
        for ($i = 0; $i -lt 10; $i++)
        {
            try
            {
                Write-Output "Try Disable Watchdog on Port: $serialPortName"
                $port = New-Object System.IO.Ports.SerialPort $serialPortName,9600,None,8,one
                $port.ReadTimeout = 1000
                $port.Open()
                $port.Write('e0')
                $reply = $port.ReadLine()
                Write-Output "reply: $reply"
                if ($reply.Contains('!:e0'))
                {
                    Write-Output 'Watchdog Disabled'
                    $watchDogDisabled = $true
                    break;
                }
            }
            catch
            {
                Write-Output "Stop WatchDog Exception:$_.Exception.Message"
            }    
            finally
            {
                $port.Close()
            }    
        }
        if ($watchDogDisabled -eq $true)
        {
            break;
        }
    }
    if ($watchDogDisabled -ne $true)
    {
        Write-Output 'Stop WatchDog Failed'
        exit 1
    }
}

Function NetworkDisableDPEMSWatchDog
{
    # Disable the DPEMS watchdog using a network call so we don't get killed part way through the installation
    # The Proxy will enable the watchdog when it starts running
    $watchDogDisabled = $false

    try
    {
        # disable the watchdog - both network and serial
        # the proxy will reenable it once it runs
        #$setting = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\setting.json | ConvertFrom-Json
        #$deviceAddress = $setting.deviceAddress
        $postCommand = "$deviceAddress/setWatchDog"
        Write-Output $postCommand

        $body = @{
            'status' = 'false'
        } | ConvertTo-Json
    
        $header = @{
            'Accept'       = 'application/json'
            'Content-Type' = 'application/json'
        }
   
        for ($i = 0; $i -lt 10; $i++)
        {
            $response = Invoke-WebRequest -Uri "$postCommand" -Method 'Post' -Body $body -Headers $header
            if ($response.StatusCode -eq 200)
            {
                Write-Output 'Stop WatchDog Successful'
                $watchDogDisabled = $true
                break;
            }
            else
            {
                Write-Output "Stop WatchDog Failed:$($response.StatusCode)"
            }
        }
    }
    catch
    {
        Write-Output "Stop WatchDog Exception:$_.Exception.Message"
    }    
    if ($watchDogDisabled -ne $true)
    {
        Write-Output 'Stop WatchDog Failed'
        exit 1
    }    
}

Write-Output 'Downloading and installing DeviceProxy'

if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output 'Powershell needs to be version 3 or greater'
    exit 1
}

$server = $args[0]
$oldInstallationFolder = $args[1]
$installationType = $args[2]
$secondPcIpAddress = $args[3]

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

if (!$oldInstallationFolder)
{
    Write-Output 'Old installation folder must be specified'
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

$settingFile = "$oldInstallationFolder\conf\setting.json"
$dataFile = "$oldInstallationFolder\data\data.json"
if ($(Test-Path -Path $settingFile) -ne $true)
{
    Write-Output "setting.json does not exist in old Installation folder $settingFile"
    exit
}
if ($(Test-Path -Path $dataFile) -ne $true)
{
    Write-Output "data.json does not exist in old Installation folder $oldInstallationFolder\..\data\data.json"
    exit
}
$settingFileJson = Get-Content "$oldInstallationFolder\conf\setting.json" -Raw | ConvertFrom-Json
$deviceId = $settingFileJson.deviceId
$deviceAddress = $settingFileJson.deviceAddress

$appsettingsJson = Get-Content "$oldInstallationFolder\bin\appsettings.json" -Raw | ConvertFrom-Json
if ($appsettingsJson.deviceMode -eq 'http')
{
    Write-Output 'device mode found: http' 
    $hardware = 'DPEMS-V2'
}
elseif ($appsettingsJson.deviceMode -eq 'serial')
{
    Write-Output 'device mode found: serial' 
    if ($appsettingsJson.DaughterBoardType -eq 'V2')
    {
        Write-Output 'daughterboard found: V2' 
        $hardware = 'DPEMS-V1_DBV2'
    }
    elseif ($appsettingsJson.DaughterBoardType -eq 'V3')
    {
        Write-Output 'daughterboard found: V3' 
        $hardware = 'DPEMS-V1_DBV3'
    }
    else
    {
        Write-Output 'DaughterBoardType not found in appsettings.json' 
        exit
    }
}
else 
{
    Write-Output 'deviceMode not found in appsettings.json' 
    exit
}

if (!$deviceId)
{
    Write-Output 'Device Id Not found in setting.json'
    exit 1
}

Switch ($hardware)
{
    'DPEMS-V1'
    {
        $secondPcIpAddress = '192.168.64.2'
    }
    'DPEMS-V1_DBV2'
    {
        $secondPcIpAddress = '192.168.64.2'
    }
    'DPEMS-V1_DBV3'
    {
        $secondPcIpAddress = '192.168.64.2'
    }
    'DPEMS-V1_FANEXT' 
    {
        $secondPcIpAddress = '192.168.64.2'
    }
    'DPEMS-V2'
    {
        if (!$deviceAddress)
        {
            Write-Output 'Device Address not found in setting.json'
            exit
        }
        else
        {
            Write-Output 'Device Address'$deviceAddress
        }
        if ($installationType -eq 'dualPC' -and !$secondPcIpAddress)
        {
            Write-Output 'Second Pc Ip Address must be specified - eg: 10.1.10.101'
            exit
        }
    }
    default
    {
        Write-Output 'hardware not found in appsetting.json'
        exit 1
    }
}
$environment = $server + '_' + $hardware

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
    if ($hardware -eq 'DPEMS-V2')
    {
        $newIPAddress = '10.10.10.1'
    }
    else
    {
        $newIPAddress = '192.168.64.1'
    }
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

Write-Output 'Remove old start.cmd file ...'
Remove-Item C:\Users\SureVision\Desktop\start.cmd -Force 2>$null

Write-Output 'Remove old RunNetworkProxy scehduled task...'
Unregister-ScheduledTask -TaskName 'RunNetworkProxy' -Confirm:$false

Write-Output 'Stop the DeviceProxy.exe process...'
taskkill /IM DeviceProxy.exe /F

Switch ($hardware)
{
    'DPEMS-V1'
    {
        SerialDisableDPEMSWatchDog
    }
    'DPEMS-V1_DBV2'
    {
        SerialDisableDPEMSWatchDog
    }
    'DPEMS-V1_DBV3'
    {
        SerialDisableDPEMSWatchDog
    }
    'DPEMS-V1_FANEXT' 
    {
        SerialDisableDPEMSWatchDog
    }
    'DPEMS-V2'
    {
        NetworkDisableDPEMSWatchDog
    }
    default
    {
        Write-Output 'hardware not found in appsetting.json'
        exit 1
    }
}

Write-Output 'Installing scoop...'
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

#create .gitconfig file - to allow sync over slow internet connections
'[http]
postBuffer = 1048576000
maxRequestBuffer = 1048576000
[https]
postBuffer = 1048576000
maxRequestBuffer = 1048576000
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

$aria2Installed = $($installedApps | Select-String -Pattern 'aria2' -CaseSensitive -SimpleMatch)
if (!$aria2Installed)
{
    scoop install aria2
}

$gitInstalled = $($installedApps | Select-String -Pattern 'git' -CaseSensitive -SimpleMatch)
if (!$gitInstalled)
{
    scoop install git
}

scoop bucket add $repo https://github.com/Design2Production/$repo.git

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
#echo settings files from applicaiton and open for editing
"{
    `"port`": `"COM2`",
    `"daughterBoardPort`": `"COM3`",
    `"deviceAddress`": `"$deviceAddress`",
    `"deviceId`": `"$deviceId`",
    `"LcdTurnOnSchedule`": `"`",
    `"LcdTurnOffSchedule`": `"`",
    `"DeviceInfoPollerScheduler`": `"* * * * *`",
    `"enableRemoteCommand`": `"true`",
    `"secondPcIpAddress`": `"$secondPcIpAddress`"
}" | Out-File -FilePath C:\ProgramData\DP\DeviceProxy\setting.json
Copy-Item 'C:\ProgramData\DP\DeviceProxy\setting.json' -Destination 'C:\ProgramData\DP\DeviceProxy\setting-backup.json' -Force
Copy-Item "$deviceProxyDirectory\data.json" -Destination 'C:\ProgramData\DP\DeviceProxy\data\data.json'

# Add auto update to scheduler
Write-Output 'Add task for Autoupdate...'
$taskName = 'DPUpdateDeviceProxy'
$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -like $taskName }
if ($taskExists)
{
    Unregister-ScheduledTask -TaskName "$taskName" -Confirm:$false 2>$null
}
$action = New-ScheduledTaskAction -Execute 'powershell' -Argument 'C:\scoop\apps\DeviceProxy\current\DPUpdateDeviceProxy.ps1'
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
$principal = New-ScheduledTaskPrincipal -UserId "$($env:USERDOMAIN)\$($env:USERNAME)" -LogonType S4U -RunLevel Highest
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

Write-Output 'Remove old DeviceProxy installation...'
Remove-Item -r $oldInstallationFolder -Force 2>$null

Write-Output 'Install DeviceProxy service'
serman install $deviceProxyXml ASP_ENV=$environment --overwrite

# write out environment so the update routine can read it
"{
    `"server`": `"$server`"
 }" | Out-File -FilePath C:\ProgramData\DP\DeviceProxy\server.json


Write-Output 'DeviceProxy installation complete'
