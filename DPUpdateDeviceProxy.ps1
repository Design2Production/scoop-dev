# Stop the Proxy Service
Stop-Service DeviceProxy

# disable the watchdog - both network and serial
# the proxy will reenable it once it runs
$setting = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\setting.json | ConvertFrom-Json
$deviceAddress = $setting.deviceAddress
$postCommand = "$deviceAddress/setWatchDog"

Write-Output $postCommand

$body = @{
    'status' = 'false'
} | ConvertTo-Json
   
$header = @{
    'Accept'       = 'application/json'
    'Content-Type' = 'application/json'
} 
   
Invoke-RestMethod -Uri "$postCommand" -Method 'Post' -Body $body -Headers $header | ConvertTo-Html | Out-Null

$serialPortNames = [System.IO.Ports.SerialPort]::getportnames()
foreach ($serialPortName in $serialPortNames)
{
    Write-Output "Disable Watchdog on Port: $serialPortName"
    $port = New-Object System.IO.Ports.SerialPort $serialPortName,9600,None,8,one
    $port.Open()
    $port.Write('e0')
    $port.Close()
}

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

Invoke-WebRequest -Uri "$serverCommand" -Method 'post' -Body $bodyUpdateStarted -Headers $header | ConvertTo-Html | Out-Null

# Execute the Update
scoop update
scoop update *

# version may be different after the upgrade if there was a new version
$version = (Get-Item C:\scoop\apps\DeviceProxy\current\DeviceProxy.dll).VersionInfo.FileVersion
$bodyUpdateEnded = @{
    'mac'           = "$deviceId"
    'proxy_version' = "$version"
    'status'        = 'update-ended'
} | ConvertTo-Json

Invoke-WebRequest -Uri "$serverCommand" -Method 'post' -Body $bodyUpdateEnded -Headers $header | ConvertTo-Html | Out-Null

# Restart the Proxy Service
Start-Service DeviceProxy