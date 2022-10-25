#Requires -RunAsAdministrator
Set-PSDebug -Trace 0

$repo = 'scoop-dev'

Function SerialDisableDPEMSWatchDog
{
    # Disable the DPEMS watchdog using a network call so we don't get killed part way through the installation
    # The Proxy will enable the watchdog when it starts running

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
}

Function NetworkDisableDPEMSWatchDog
{
    # Disable the DPEMS watchdog using a network call so we don't get killed part way through the installation
    # The Proxy will enable the watchdog when it starts running

    try
    {
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
    }
    catch
    {
        Write-Output "Stop WatchDog Exception:$_.Exception.Message"
    }    
}

Write-Output 'Uninstalling DeviceProxy'

if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output 'Powershell needs to be version 3 or greater'
    exit 1
}

$myshell = New-Object -com 'Wscript.Shell'

SerialDisableDPEMSWatchDog
NetworkDisableDPEMSWatchDog

Write-Output 'Stop DeviceProxy Service...'
Stop-Service DeviceProxy 2>$null

serman uninstall DeviceProxy
scoop uninstall DeviceProxy
scoop uninstall serman
scoop uninstall 7zip
scoop uninstall git
scoop uninstall scoop $myshell.sendkeys('Y') $myshell.sendkeys('{ENTER}')

Remove-Item -Recurse 'C:\scoop'
Remove-Item -Recurse 'C:\serman'

Write-Output 'DeviceProxy uninstallation complete'
