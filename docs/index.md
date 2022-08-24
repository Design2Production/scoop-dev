# DP Proxy Windows Installation

1. Start Powershell as Administrator
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission

2. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallDeviceProxy.ps1 -OutFile InstallDeviceProxy.ps1
</pre>

3. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All** + **ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

4. Run the install script with the following arguments
    1. Server: **Production** | **Staging**
    2. Hardware: **DPEMS-V1** | **DPEMS-V1_DBV2** | **DPEMS-V1_DBV3** | **DPEMS-V1_FANEXT** | **DPEMS-V2**
    3. Installation: **new** | **fullPathOfOldDeviceProxy.exeFolder**
<pre>
.\InstallDeviceProxy.ps1 Staging DPEMS-V2 new
.\InstallDeviceProxy.ps1 Production DPEMS-V2 C:\ProgramFiles\DP\DeviceProxy
</pre>

5. Delete the install script
<pre>
rm ./InstallDeviceProxy.ps1
</pre>

