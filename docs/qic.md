# DP Windows Installation for QIC

# DeviceProxy Installation

## Pre Installation
1. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission


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
   1. <pre>Production - which server to use: Staging | Production</pre>
   2. <pre>new - old installation folder: new | old Installation Folder</pre>
   3. <pre>singlePc - InstallationType: singlePC|dualPC</pre>
   4. <pre>QIC-Indoor-002 = Unique DeviceId</pre>
   5. <pre>DPEMS-V1_DBV2 = DPEMS Hardware: DPEMS-V1 | DPEMS-V1_DBV2 | DPEMS-V1_DBV3 | DPEMS-V1_FANEXT | DPEMS-V2</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>
