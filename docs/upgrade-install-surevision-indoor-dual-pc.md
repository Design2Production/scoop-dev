# DP Upgrade Installation for SureVision - Indoor - Dual PC

# Pre Installation
Ensure the Ethernet connection to the switch (connected to the internet) is made prior to installation, otherwise the automatic network configuration will throw an exception and abort the installation.

On Both PCs:

    1. Connect the longer Ethernet cable from the PCs to the swith to the left most port (when looking from the front of the PC)
    2. Connect the short Ethernet cable between the PCs to the right most port (when looking from the front of the PC)

# RemoteCommandRunner Installation

***The Remote command runner should ONLY be installed on the "Second" PC in a dual PC setup.***

If setting up a new PC B installtion follow [these](https://design2production.github.io/scoop-dev/new-rcr-install-surevision-indoor-pc.html) instructions.

If upgrading an old PC B installation follow [these](https://design2production.github.io/scoop-dev/upgrade-rcr-install-surevision-indoor-pc.html) instructions:

# DeviceProxy Installation

1. Start Powershell as Administrator
<pre>
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission
</pre>

2. Download the install script to UPGRADE an old installation
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/UpgradeInstallDeviceProxy.ps1 -OutFile UpgradeInstallDeviceProxy.ps1
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

3. Run the install script:

<pre>.\UpgradeInstallDeviceProxy.ps1 Production "C:\Program Files\dp-NetworkProxy-SureVision-Indoor-Windows-V1.6" dualPC</pre>

The arguments are as follows:

<pre>
                                                      Production = which server to use: Staging | Production
"C:\Program Files\dp-NetworkProxy-Surevision-Indoor-Windows-V1.6 = old installation folder
                                                        singlePc = InstallationType: singlePC|dualPC
</pre>

> Ensure there are no errors reported during installation - it can take a long time to install, particularly on machines with slow or intermittant internet***