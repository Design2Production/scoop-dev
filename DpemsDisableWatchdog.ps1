Write-Output "DisableWatchDog:$PSScriptRoot"

$setting = Get-Content -Raw -Path C:\ProgramData\DP\DeviceProxy\setting.json | ConvertFrom-Json
$deviceAddress = $setting.deviceAddress
$postCommand = "$deviceAddress/setWatchDog"

Write-Output $postCommand

$body = @{
    'status' = 'false'
} | ConvertTo-Json
   
$header = @{
    'Accept'          = 'application/json'
    'connectapitoken' = '97fe6ab5b1a640909551e36a071ce9ed'
    'Content-Type'    = 'application/json'
} 
   
Invoke-RestMethod -Uri "$postCommand" -Method 'Post' -Body $body -Headers $header | ConvertTo-Html

$serialPortNames = [System.IO.Ports.SerialPort]::getportnames()
foreach ($serialPortName in $serialPortNames)
{
    Write-Output "Open Port: $serialPortName"
    $port = New-Object System.IO.Ports.SerialPort $serialPortName,9600,None,8,one
    $port.Open()
    Write-Output 'read ---'
    Write-Output $port.ReadLine()
    Write-Output 'write-e0'
    $port.Write('e0')
    Write-Output 'read ---'
    Write-Output $port.ReadLine()
    Write-Output 'done ---'
    $port.Close()
    Write-Output "Close Port: $serialPortName"
}
