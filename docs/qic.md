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

3. Run the install script with the following arguments
    1. <pre>Server: Production</pre>
    2. <pre>Installation: new</pre>
    3. <pre>InstallationType: singlePC</pre>
    4. <pre>Hardware: DPEMS-V1_DBV2</pre>
So the following command line will install the proxy in a production environment
<pre>
.\InstallDeviceProxy.ps1 Production new singlePC DeviceId DPEMS-V1_DBV2
</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>
