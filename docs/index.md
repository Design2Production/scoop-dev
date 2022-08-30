# DP Windows Installation

[DeviceProxy Installation](#deviceproxy-installation)

[RemoteCommandRunner Installation](#remotecommandrunner-installation)

# DeviceProxy Installation

## Pre Installation
1. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

2. If Updating an existing machine remove the old start batch file
<pre>
rm <b>pathToDesktop</b>/start.cmd
</pre>
So for SureVision, this will be 
<pre>
rm C:\Users\SureVision\Desktop\start.cmd
</pre>

3. If Update an existing machine, remove the old run task
<pre>
Unregister-ScheduledTask -TaskName "RunNetworkProxy" -Confirm:$false
</pre>
If your previous installation had a different task name created, you can also open <b>Task Scheduler</b> to ensure the start up task has been removed

## Installation

1. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallDeviceProxy.ps1 -OutFile InstallDeviceProxy.ps1
</pre>

2. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

3. Run the install script with the following arguments
    1. <pre>Server: Production | Staging</pre>
    2. <pre>Hardware: DPEMS-V1 | DPEMS-V1_DBV2 | DPEMS-V1_DBV3 | DPEMS-V1_FANEXT | DPEMS-V2</pre>
    3. <pre>Installation: new | <i>fullPathOfOldDeviceProxyFolder</i></pre>
<pre>
.\InstallDeviceProxy.ps1 Staging DPEMS-V2 new
.\InstallDeviceProxy.ps1 Production DPEMS-V2 C:\ProgramFiles\DP\DeviceProxy
</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>

2. Delete the old installation
<pre>
rm -r <b>OldInstallationFolder</b>
</pre>





# RemoteCommandRunner Installation

## Pre Installation
1. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

2. If Updating an existing machine remove the old start batch file
<pre>
rm <b>pathToDesktop</b>/start.cmd
</pre>
So for SureVision, this will be 
<pre>
rm C:\Users\SureVision\Desktop\start.cmd
</pre>

3. If Update an existing machine, remove the old run task
<pre>
Unregister-ScheduledTask -TaskName "RunRemoteCommandRunner" -Confirm:$false
</pre>
If your previous installation had a different task name created, you can also open <b>Task Scheduler</b> to ensure the start up task has been removed

## Installation

1. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallRemoteCommandRunner.ps1 -OutFile InstallRemoteCommandRunner.ps1
</pre>

2. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

3. Run the install script
<pre>
.\InstallRemoteCommandRunner.ps1
</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallRemoteCommandRunner.ps1
</pre>

2. Delete the old installation
<pre>
rm -r <b>OldInstallationFolder</b>
</pre>

