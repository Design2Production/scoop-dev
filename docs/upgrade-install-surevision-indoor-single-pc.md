# DP Windows Upgrade Installation for SureVision - Indoor - Single PC

[DeviceProxy Upgrade Installation](#upgrading-the-proxy-installation)

[DeviceProxy Uninstallation](#uninstallation)

[Notes on Cloning of PCs](#notes-on-cloning-of-pcs)

# DeviceProxy Installation

## Pre Installation
1. Ensure the Ethernet connection to the switch (connected to the internet) is made prior to installation, otherwise the automatic network configuration will throw an exception and abort the installation.

    1. Connect the longer Ethernet cable from the PCs to the swith to the left most port (when looking from the front of the PC)

2. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

3. Remove the old start batch file which was previously located in the desktop folder

<pre> rm C:\Users\SureVision\Desktop\start.cmd </pre>

4. Remove the old run task from the scheduler

<pre> Unregister-ScheduledTask -TaskName "RunNetworkProxy" -Confirm:$false </pre>
*If your previous installation had a different task name created, you can also open <b>Task Scheduler</b> to ensure the start up task has been removed*

5. Stop the old proxy from running
<pre> taskkill /IM DeviceProxy.exe /F </pre>

## Upgrading the proxy installation

1. Download the install script to UPGRADE an old installation
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop/UpgradeInstallDeviceProxy.ps1 -OutFile UpgradeInstallDeviceProxy.ps1
</pre>

If the installation script fails with ***Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel*** then enter the following command and retry the Web-Request
<pre>
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
</pre>

2. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

3. Run the install script:

<pre>.\UpgradeDeviceProxy.ps1 Production "C:\Program Files\dp-NetworkProxy-SureVision-Indoor-Windows-V1.6" singlePC</pre>

The arguments are as follows:
   <pre>Production = which server to use: Staging | Production</pre>
   <pre>"C:\Program Files\dp-NetworkProxy-Surevision-Indoor-Windows-V1.6 = old installation folder</pre>
   <pre>singlePc = InstallationType: singlePC|dualPC</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./UpgradeInstallDeviceProxy.ps1
</pre>

2. Delete the old installation
<pre>
rm -r "C:\Program Files\dp-NetworkProxy-SureVision-Indoor-Windows-V1.6"
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