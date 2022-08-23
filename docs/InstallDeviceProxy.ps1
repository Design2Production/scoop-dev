Set-PSDebug -Trace 0

Write-Output "Downloading and installing DeviceProxy"

if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output "Powershell needs to be version 3 or greater"
    exit
}

$server = $args[0]
$hardware = $args[1]
$installation = $args[2]

Switch ($server)
{
    "Staging" {}
    "Production" {}
    default
    {
        Write-Output "server needs to be specified Production | Staging"
        exit
    }
}
$server = "Windows" + $server

Switch ($hardware)
{
    "DPEMS-V1" {}
    "DPEMS-V1_DBV2" {}
    "DPEMS-V1_DBV3" {}
    "DPEMS-V1_FANEXT" {}
    "DPEMS-V2" {}
    default
    {
        Write-Output "hardware needs to be specified DPEMS-V1 | DPEMS-V1_DBV2 | DPEMS-V1_DBV3 | DPEMS-V1_FANEXT | DPEMS-V2"
        exit
    }
}
$environment = $server + $hardware

if (!$installation)
{
    Write-Output "Installation must be specified new | old_installation_folder"
    exit
}

$env:SCOOP='C:\scoop'
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')

try
{
    scoop info | out-null
}
catch
{
    Write-Output "Installing Scoop package management system..."

    iex "& {$(irm get.scoop.sh)} -RunAsAdmin"
    #Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

    scoop bucket add scoop-dev https://github.com/Design2Production/scoop-dev.git
}

scoop update

$installedApps = $(scoop list)
#$sudoInstalled = $($installedApps | Select-String -Pattern 'sudo' -CaseSensitive -SimpleMatch)
$sermanInstalled = $($installedApps | Select-String -Pattern 'serman' -CaseSensitive -SimpleMatch)
$deviceProxyInstalled = $($installedApps | Select-String -Pattern 'DeviceProxy' -CaseSensitive -SimpleMatch)
#if (!$sudoInstalled)
#{
    #scoop install sudo
#}
if (!$sermanInstalled)
{
    scoop install serman
}
if (!$deviceProxyInstalled)
{
    scoop install DeviceProxy
}

New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\cache\firmware | Out-Null
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\data | Out-Null
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\log | Out-Null

$scoopDirectory = $(scoop prefix DeviceProxy)

if ($installation -eq "new")
{
    #copy settings files from applicaiton and open for editing
    Copy-Item "$scoopDirectory\setting.json" -Destination "C:\ProgramData\DP\DeviceProxy\setting.json"
    Write-Output "Editing setting.json in Notepad - Save file and exit Notepad to continue..."
    notepad.exe C:\ProgramData\DP\DeviceProxy\setting.json | Out-Null
    Write-Output "setting.json saved"
    Write-Output "Editing data.json in Notepad - Save file and exit Notepad to continue..."
    Copy-Item "$scoopDirectory\data.json" -Destination "C:\ProgramData\DP\DeviceProxy\data\data.json"
    notepad.exe C:\ProgramData\DP\DeviceProxy\data\data.json | Out-Null
    Write-Output "data.json saved"
}
else
{
    #copy settings files from old installation
    Copy-Item "$installation\..\conf\setting.json" -Destination "C:\ProgramData\DP\DeviceProxy\setting.json"
    Copy-Item "$installation\..\data\data.json" -Destination "C:\ProgramData\DP\DeviceProxy\data\data.json"
}

# Add auto update to scheduler
$scoopUpdateXml = $scoopDirectory + "\Scoop.Update.Apps.xml"
$taskName = "Scoop.Update.Apps"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }

if ($taskExists)
{
    Unregister-ScheduledTask -TaskName "Scoop.Update.Apps" -Confirm:$false
}
Register-ScheduledTask -xml (Get-Content $scoopUpdateXml | Out-String) -TaskName "Scoop.Update.Apps" -TaskPath "\DP\"

$deviceProxyXml = $scoopDirectory + "\DeviceProxy.xml"
# Add DeviceProxy as Windows Service
serman uninstall DeviceProxy
serman install $deviceProxyXml ASP_ENV=$environment --overwrite