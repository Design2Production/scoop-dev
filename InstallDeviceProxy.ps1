


# Add auto update to scheduler
Register-ScheduledTask -xml (Get-Content 'Scoop.Update.Apps.xml' | Out-String) -TaskName "Scoop.Update.Apps" -TaskPath "\DP\"