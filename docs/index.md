# Design to Production - Scoop Dev
Design to Production windows scoop repo storage

# DP Proxy Windows Installation

1. Open a Powershell on the windows computer you wish to install the DeviceProxy to
2. Download the install script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/InstallDeviceProxy.ps1 -OutFile InstallDeviceProxy.ps1
</pre>
3. Allow Powershell to execute local scripts
<pre>
set-executionpolicy remotesigned -scope currentuser
</pre>
4. Run the install script
<pre>
.\InstallDeviceProxy.ps1
</pre>

