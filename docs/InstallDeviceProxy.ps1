Write-Output "Downloading and installing Scoop installation management system..."

if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output "Powershell needs to be version 3 or greater"
    exit
}

$env:SCOOP='C:\scoop'
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

scoop bucket add scoop-dev https://github.com/Design2Production/scoop-dev.git
scoop update
scoop install sudo
scoop install serman
scoop install DeviceProxy

New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\cache\firmware
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\data
New-Item -ItemType Directory -Force -Path C:\ProgramData\DP\DeviceProxy\log

# Add auto update to scheduler

Register-ScheduledTask -xml (Get-Content 'Scoop.Update.Apps.xml' | Out-String) -TaskName "Scoop.Update.Apps" -TaskPath "\DP\"

# Add DeviceProxy as Windows Service
sudo serman install DeviceProxy.xml ASP_ENV="WindowsStaging_DPEMS-V2"