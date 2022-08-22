if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output "Powershell needs to be version 3 or greater"
    exit
}

Write-Output "Powershell version:$($psversiontable.psversion.major) OK"

Write-Output "Downloading and installing Scoop"

$env:SCOOP='C:\scoop'
[environment]::setEnvironmentVariable('SCOOP',$env:SCOOP,'User')
Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

scoop update

# Add auto update to scheduler
#Register-ScheduledTask -xml (Get-Content 'Scoop.Update.Apps.xml' | Out-String) -TaskName "Scoop.Update.Apps" -TaskPath "\DP\"