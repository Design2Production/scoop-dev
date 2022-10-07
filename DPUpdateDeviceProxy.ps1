# Stop the Proxy Service
Stop-Service DeviceProxy

# ping the DPEMS
$serverJson = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\server.json | ConvertFrom-Json
$server = $serverJson.server
$endPoint = '/proxy-status.json'

$setting = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\setting.json | ConvertFrom-Json
$deviceId = $setting.deviceId

$bodyUpdateStarted = @{
    'mac'           = "$deviceId"
    'proxy_version' = "$version"
    'status'        = 'update-started'
} | ConvertTo-Json

$header = @{
    'Accept'       = 'application/json'
    'Content-Type' = 'application/json'
} 

Write-Output "S:$server D:$deviceId V:$version"

$ScriptPath = "$PSScriptRoot\DpemsPing.ps1"

Switch ($server)
{
    'WindowsStaging'
    {
        $serverCommand = "https://d2p-ems-staging.herokuapp.com$endPoint"
    }
    default
    {
        $serverCommand = "https://www.dp-ems.com$endPoint"
    }
}

Write-Output "ScriptPath:$ScriptPath"
Write-Output "ServerCommand:$serverCommand"

Invoke-WebRequest -Uri "$serverCommand" -Method 'post' -Body $bodyUpdateStarted -Headers $header | ConvertTo-Html

$JobContent = {
    & $using:ScriptPath
}

$Job = Start-Job -ScriptBlock $JobContent

# Execute the Update
scoop update
scoop update *

# Stop the DPEMS Ping
New-Item -Path "$PSScriptRoot" -Name 'stopDpemsPing.flg'

Write-Output 'starting wait'

$timeOut = 30
while ($Job.State -ne 'Completed')
{
    Write-Output 'waiting'
    if ($timeOut -le 0)
    {
        Write-Output 'timeout'
        break;
    }
    Start-Sleep -Seconds 1
    $timeOut = $timeOut - 1
}

if ($timeOut -le 0)
{
    Write-Output 'Stop Job'
    Stop-Job $Job
}

# version may be different after the upgrade if there was a new version
$version = (Get-Item C:\scoop\apps\DeviceProxy\current\DeviceProxy.dll).VersionInfo.FileVersion
$bodyUpdateEnded = @{
    'mac'           = "$deviceId"
    'proxy_version' = "$version"
    'status'        = 'update-ended'
} | ConvertTo-Json

Invoke-WebRequest -Uri "$serverCommand" -Method 'post' -Body $bodyUpdateEnded -Headers $header | ConvertTo-Html

# Restart the Proxy Service
Start-Service DeviceProxy