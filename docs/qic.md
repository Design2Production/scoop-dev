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
    2. <pre>Hardware: DPEMS-V1_DBV2</pre>
    4. <pre>Installation: new</pre>
    5. <pre>InstallationType: singlePC</pre>
So the following command line will install the proxy in a production environment
<pre>
.\InstallDeviceProxy.ps1 Production DPEMS-V1_DBV2 new singlePC
</pre>

## Configuration
When prompted to edit the settings file, ensure the deviceId is set to a unique value. 

Leave the deviceAddress as it is, it is not used for indoor units.

The deviceId is what will identify the devie in the DPEMS portal

The port and daughterBoardPort will be automatically detected - the values here will be updated by the proxy when it starts.

The file should look like this, ready for you to edit the deviceId

<pre>
{
  "port": "COM6",
  "daughterBoardPort": "COM7",
  "deviceAddress": "http://192.168.0.28:8000",
  "deviceId": "UniqueIdentifier",
  "LcdTurnOnSchedule": "",
  "LcdTurnOffSchedule": "",
  "DeviceInfoPollerScheduler": "* * * * *",
  "enableRemoteCommand": "true"
}
</pre>

## Post Instllation

1. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>