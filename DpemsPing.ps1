Write-Output "DSP:$PSScriptRoot"

$pingFlagFile = "$PSScriptRoot\stopDpemsPing.flg"
$setting = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\setting.json | ConvertFrom-Json
$deviceAddress = $setting.deviceAddress
$postCommand = "$deviceAddress/sayHello"
$run = $true

Write-Output 'remove stop file'
Remove-Item -Path "$pingFlagFile" -ErrorAction SilentlyContinue

do
{
    Write-Output "Ping DPEMS:$postCommand"
    Invoke-WebRequest -Uri "$postCommand" -Method POST
    
    $serialPortNames = [System.IO.Ports.SerialPort]::getportnames()
    foreach ($serialPortName in $serialPortNames)
    {
        Write-Output "Open Port: $serialPortName"
        $port = New-Object System.IO.Ports.SerialPort $serialPortName,9600,None,8,one
        $port.Open()
        $port.Write('h')
        Write-Output $port.ReadLine()
        $port.Close()
        Write-Output "Close Port: $serialPortName"
    }
    Start-Sleep -Seconds 10
    $run = ($(Test-Path -Path "$pingFlagFile") -ne $true)
} while ($run)

Write-Output 'remove stop file'
Remove-Item -Path "$pingFlagFile" -ErrorAction SilentlyContinue
Write-Output 'done'
