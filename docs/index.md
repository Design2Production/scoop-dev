# DP Proxy Windows Installation

1. Start Powershell
    1. Press the **Windows** key
    2. Type Powershell
    3. Click on Powershell to open it

2. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallDeviceProxy.ps1 -OutFile InstallDeviceProxy.ps1
</pre>

3. Allow Powershell to execute local scripts, when prompted, select **[A] Yes to All + ENTER** to allow local scripts to be executed
<pre>
set-executionpolicy remotesigned -scope currentuser  
</pre>

4. Run the install script
<pre>
.\InstallDeviceProxy.ps1
</pre>

