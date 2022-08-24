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
$environment = $server + "_" + $hardware

if (!$installation)
{
    Write-Output "Installation must be specified new | old_installation_folder"
    exit
}

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
Write-Output "Create ProgramData directories..."
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\cache\firmware | Out-Null
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\data | Out-Null
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\log | Out-Null

Write-Output "Copy data files..."
$deviceProxyDirectory = $(scoop prefix DeviceProxy)
if ($installation -eq "new")
{
    #copy settings files from applicaiton and open for editing
    Copy-Item "$deviceProxyDirectory\setting.json" -Destination "C:\ProgramData\DP\DeviceProxy\setting.json"
    Write-Output "Editing setting.json in Notepad - Save file and exit Notepad to continue..."
    notepad.exe C:\ProgramData\DP\DeviceProxy\setting.json | Out-Null
    Write-Output "setting.json saved"
    Write-Output "Editing data.json in Notepad - Save file and exit Notepad to continue..."
    Copy-Item "$deviceProxyDirectory\data.json" -Destination "C:\ProgramData\DP\DeviceProxy\data\data.json"
    notepad.exe C:\ProgramData\DP\DeviceProxy\data\data.json | Out-Null
    Write-Output "data.json saved"
}
else
{
    #copy settings files from old installation
    Copy-Item $settingFile -Destination "C:\ProgramData\DP\DeviceProxy\setting.json"
    Copy-Item $dataFile -Destination "C:\ProgramData\DP\DeviceProxy\data\data.json"
}

# Add auto update to scheduler
Write-Output "Add task for Autoupdate..."
$dpUpdateAppsXml = $deviceProxyDirectory + "\DPUpdateApps.xml"
$taskName = "DPUpdateApps"
$taskExists = Get-ScheduledTask | Where-Object {$_.TaskName -like $taskName }
if ($taskExists)
{
    Unregister-ScheduledTask -TaskName "DPUpdateApps" -Confirm:$false
}
Register-ScheduledTask -xml (Get-Content $dpUpdateAppsXml | Out-String) -TaskName "DPUpdateApps" -TaskPath "\DP\" | out-null

# Add DeviceProxy as Windows Service
$deviceProxyXml = $deviceProxyDirectory + "\DeviceProxy.xml"
try
{
    Write-Output "Stop DeviceProxy Service..."
    Stop-Service DeviceProxy | out-null
}
catch {}
try
{
    Write-Output "Uninstall serman..."
    serman uninstall DeviceProxy | out-null
    Write-Output "Remove serman cache..."
    Remove-Item C:\serman\* -Recurse -Force | out-null
    Remove-Item C:\serman\ | out-null
}
catch{}
Write-Output "Install DeviceProxy service"
serman install $deviceProxyXml ASP_ENV=$environment --overwrite
Write-Output "DeviceProxy installation complete"
