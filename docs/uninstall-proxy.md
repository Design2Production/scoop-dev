# DP Uninstallation of Proxy

1. Download the uninstall script
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/UnInstallDeviceProxy.ps1 -OutFile UnInstallDeviceProxy.ps1
</pre>

> If the installation script fails with:
>
> ***Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel***
> then enter the following command and retry the Invoke-Web-Request command
> <pre>
> [Net.ServicePointManager]::SecurityProtocol = "tls12, tls11, tls"
> </pre>
> If the installation script can't run then enter the following command to allow Powershell to execute local scripts.
> <pre>
> Set-Executionpolicy remotesigned -scope currentuser -Force 
> </pre>

3. Run the uninstall script:
<pre>
.\UnInstallDeviceProxy.ps1
</pre>
