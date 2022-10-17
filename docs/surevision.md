# DP Windows Installation for Surevision

[DeviceProxy Installation](#deviceproxy-installation)

[RemoteCommandRunner Installation for Double Sided Units](#remotecommandrunner-installation)

# DeviceProxy Installation

## Pre Installation
1. For new ***singlePC*** installations, ensure the Ethernet connection to the switch (connected to the internet) is made prior to installation, otherwise the automatic network configuration will throw an exception and abort the installation.

2. For new ***dualPC*** installations, ensure the Ethernet connections are made prior to installation, otherwise the automatic network configuration will throw an exception and abort the installation.

    ### For Indoor Units
    1. On both PCs, connect the short Ethernet cable between the PCs to the right most port (when looking from the front of the PC)
    2. On both PCs, connect the longer Ethernet cables from the PCs to the swith to the left most port (when looking from the front of the PC)

    ### For Outdoor Units
    1. On the main PC, connect the short Etherbet cable to the DPEMS to the left more port (when looking from the front of the PC)
    2. On the main PC, connect the longer Ethernet cable from the PC to the swith to the right most port (when looking from the front of the PC)
    3. On the second PC, connect the longer Ethernet cable from the PC to the swith to the left most port (when looking from the front of the PC)

3. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

4. If Updating an existing machine (Note: this will be automated in a future version of the installation script)

    1. Remove the old start batch file which was previously located in the desktop folder
    <pre> rm <b>pathToDesktop</b>/start.cmd </pre>

    2. Remove the old run task from the scheduler
    <pre> Unregister-ScheduledTask -TaskName "RunNetworkProxy" -Confirm:$false </pre>
    *If your previous installation had a different task name created, you can also open <b>Task Scheduler</b> to ensure the start up task has been removed*

## Installation

1. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallDeviceProxy.ps1 -OutFile InstallDeviceProxy.ps1
</pre>

If the installation script fails with ***Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel*** then enter the following command and retry the Web-Request
<pre>
[Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
</pre>

2. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

3. Run the install script with the appropraite installation parameters for example:
<pre>
.\InstallDeviceProxy.ps1 Production new singlePC QIC-Indoor-002 DPEMS-V1_DBV2
</pre>
The arguments are as follows:
   1. <pre>Production = which server to use: Staging | Production</pre>
   2. <pre>new = old installation folder: new | old Installation Folder</pre>
   3. <pre>singlePc = InstallationType: singlePC|dualPC</pre>
   4. <pre>QIC-Indoor-002 = Unique DeviceId</pre>
   5. <pre>DPEMS-V1_DBV2 = DPEMS Hardware Indoor Units: DPEMS-V1 | DPEMS-V1_DBV2 | DPEMS-V1_DBV3 | DPEMS-V1_FANEXT</pre>
   6. <pre>DPEMS-V1_DBV2 = DPEMS Hardware Outdoor Units: DPEMS-V2</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>

2. Delete the old installation (Note: this will be automated in a future version of the installation script)
<pre>
rm -r <b>OldInstallationFolder</b>
</pre>

# RemoteCommandRunner Installation for Double Sided Units

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
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallRemoteCommandRunner.ps1 -OutFile InstallRemoteCommandRunner.ps1
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
.\InstallRemoteCommandRunner.ps1
</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallRemoteCommandRunner.ps1
</pre>

2. Delete the old installation (Note: this will be automated in a future version of the installation script)
<pre>
rm -r <b>OldInstallationFolder</b>
</pre>
