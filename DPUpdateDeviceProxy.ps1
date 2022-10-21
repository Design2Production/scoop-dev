$setting = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\setting.json | ConvertFrom-Json
$deviceId = $setting.deviceId
$deviceAddress = $setting.deviceAddress

if ($deviceId)
{
    $logFilename = "DeviceProxy-$deviceId-UpdateLog.txt"
}
else
{
    $logFilename = 'DeviceProxy-NoDeviceIdFound-UpdateLog.txt'
}
Start-Transcript -Append "C:\ProgramData\DP\DeviceProxy\log\$logFilename"

Write-Output '------------------------------------------------------------------------------'
Write-Output "Start Device Proxy Update at $(Get-Date)"

Stop-Service DeviceProxy

$serialPortNames = [System.IO.Ports.SerialPort]::getportnames()
$watchDogDisabled = $false

foreach ($serialPortName in $serialPortNames)
{
    for ($i = 0; $i -lt 3; $i++)
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

if ($watchDogDisabled -eq $false)
{
    try
    {
        # disable the watchdog - both network and serial
        # the proxy will reenable it once it runs
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
    }
    catch
    {
        Write-Output "Stop WatchDog Exception:$_.Exception.Message"
    }    
}

try 
{
    # ping the Portal
    Write-Output 'Ping the portal -> update start'
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

    Write-Output "Server Ping parameters S:$server D:$deviceId V:$version "

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

    Write-Output "ServerCommand:$serverCommand"

    Invoke-WebRequest -Uri "$serverCommand" -Method 'post' -Body $bodyUpdateStarted -Headers $header | ConvertTo-Html | Out-Null
}
catch 
{
    Write-Output "Ping Update Start Exception:$_.Exception.Message"
}
    
Write-Output 'Start Update'

try
{
    # Execute the Update
    scoop update
    scoop update *
}
catch
{
    Write-Output "Update Exception:$_.Exception.Message"
}

try
{
    # version may be different after the upgrade if there was a new version
    $version = (Get-Item C:\scoop\apps\DeviceProxy\current\DeviceProxy.dll).VersionInfo.FileVersion
    $bodyUpdateEnded = @{
        'mac'           = "$deviceId"
        'proxy_version' = "$version"
        'status'        = 'update-ended'
    } | ConvertTo-Json

    Write-Output 'Ping the portal -> Update end'

    Invoke-WebRequest -Uri "$serverCommand" -Method 'post' -Body $bodyUpdateEnded -Headers $header | ConvertTo-Html | Out-Null
}
catch
{
    Write-Output "Ping Updated End Exception:$_.Exception.Message"
}

Write-Output 'Start Device Proxy Service'

# Restart the Proxy Service
Start-Service DeviceProxy

Write-Output 'Update script complete'
Write-Output '------------------------------------------------------------------------------'

Stop-Transcript
