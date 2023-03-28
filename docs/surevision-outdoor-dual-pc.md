# DP Windows Installation for Surevision

[RemoteCommandRunner Installation](#remotecommandrunner-installation)

[DeviceProxy Installation](#deviceproxy-installation)

[DeviceProxy Uninstallation](#deviceproxy-uninstallation)

[Notes on Cloning of PCs](#notes-on-cloning-of-pcs)

## Pre Installation
Ensure the Ethernet connections are made prior to installation, otherwise the automatic network configuration will throw an exception and abort the installation.

On the main PC, connect the short Ethernet cable between the PC and the DPEMS to the right most port (when looking from the front of the PC)
On both PCs, connect the longer Ethernet cables from the PCs to the swith to the left most port (when looking from the front of the PC)

# RemoteCommandRunner Installation

***The Remote command runner should ONLY be installed on the "Second" PC in a dual PC setup.***

## Pre Installation
1. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

2. If Updating an existing machine (Note: this will be automated in a future version of the installation script)

    1. Remove the old start batch file
    <pre>
    rm <b>pathToDesktop</b>/start.cmd
    </pre>

    2. Remove the old run task from the scheduler
    <pre>
    Unregister-ScheduledTask -TaskName "RunRemoteCommandRunner" -Confirm:$false
    </pre>
    *If your previous installation had a different task name created, you can also open <b>Task Scheduler</b> to ensure the start up task has been removed*

## Installation

1. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop/InstallRemoteCommandRunner.ps1 -OutFile InstallRemoteCommandRunner.ps1
</pre>

If the installation script fails with ***Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel*** then enter the following command and retry the Web-Request
<pre>
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
</pre>


2. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

3. Run the install script
<pre>
.\InstallRemoteCommandRunner.ps1 DPEMS-V2
</pre>

4. During the installation script the IP Address of the unit will be reported. Note this IP address, as it is needed when installing the Device Proxy (see below).

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallRemoteCommandRunner.ps1
</pre>

2. Delete the old installation (Note: this will be automated in a future version of the installation script)
<pre>
rm -r <b>OldInstallationFolder</b>
</pre>

# DeviceProxy Installation

1. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

2. If Updating an existing machine (Note: this will be automated in a future version of the installation script)

    1. Remove the old start batch file which was previously located in the desktop folder
    <pre> rm <b>pathToDesktop</b>/start.cmd </pre>

    2. Remove the old run task from the scheduler
    <pre> Unregister-ScheduledTask -TaskName "RunNetworkProxy" -Confirm:$false </pre>
    *If your previous installation had a different task name created, you can also open <b>Task Scheduler</b> to ensure the start up task has been removed*

3. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop/InstallDeviceProxy.ps1 -OutFile InstallDeviceProxy.ps1
</pre>

If the installation script fails with ***Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel*** then enter the following command and retry the Web-Request
<pre>
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
</pre>

4. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

5. Run the install script with the appropraite installation parameters.

<pre>.\InstallDeviceProxy.ps1 Production new dualPC Surevision-Outdoor-002 DPEMS-V2 10.10.10.3 10.1.10.101</pre> 

The arguments are as follows:
<pre>Production = which server to use: Staging | Production</pre>
<pre>new = old installation folder: new | old Installation Folder</pre>
<pre>singlePc = InstallationType: singlePC|dualPC</pre>
<pre>Surevision-Indoor-002 = Unique DeviceId</pre>
<pre>DPEMS-V1_DBV2 = DPEMS Hardware Indoor Units: DPEMS-V1 | DPEMS-V1_DBV2 | DPEMS-V1_DBV3 | MS-V1_FANEXT</pre>
<pre>DPEMS-V1_DBV2 = DPEMS Hardware Outdoor Units: DPEMS-V2</pre>
<pre>10.10.10.3 = The Ip Address of the DPEMS-V2</pre>
<pre>10.1.10.101 = The Ip Address of the second PC as noted down when installing the RemoteCommandRunner above</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>

2. Delete the old installation (Note: this will be automated in a future version of the installation script)
<pre>
rm -r <b>OldInstallationFolder</b>
</pre>

# DeviceProxy Uninstallation

1. Download the uninstall script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop/UnInstallDeviceProxy.ps1 -OutFile UnInstallDeviceProxy.ps1
</pre>

If the installation script fails with ***Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel*** then enter the following command and retry the Web-Request
<pre>
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
</pre>

2. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

3. Run the uninstall script:
<pre>
.\UnInstallDeviceProxy.ps1
</pre>

# Notes on cloning of PCs

You can follow this installation proceedure for your main and secondard PCs and then clone the images for faster production deployment, however, the ***deviceID*** filed will then be the same on the new images.

After cloning, the ***C:\ProgramData\DP\DeviceProxy\setting.json*** file must be edited and the ***deviceId*** field must be made unique.

The contents of the file will look like the following:
<pre>
{
  "port": "COM6",
  "daughterBoardPort": "COM7"
  "deviceAddress": "http://10.10.10.3:8000",
  "deviceId": "UNIQUE-DEVICE-ID",
  "LcdTurnOnSchedule": "",
  "LcdTurnOffSchedule": "",
  "DeviceInfoPollerScheduler": "* * * * *",
  "enableRemoteCommand": "true",
  "secondPcIpAddress": "192.168.0.200",
}
</pre>

Please ensure you don't accidentally remove or change any punctuation. Only change the value of the deviceId inside the double quotes "UNIQUE-DEVICE-ID".