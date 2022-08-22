if ( $psversiontable.psversion.major -lt 3 )
{
    Write-Output "Powershell needs to be version 3 or greater"
    exit
}

Write-Output "Powershell version:$($psversiontable.psversion.major)"


# Add auto update to scheduler
#Register-ScheduledTask -xml (Get-Content 'Scoop.Update.Apps.xml' | Out-String) -TaskName "Scoop.Update.Apps" -TaskPath "\DP\"