#Requires -RunAsAdministrator
Set-PSDebug -Trace 0

# Disable the DPEMS watchdog using a serial call 
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