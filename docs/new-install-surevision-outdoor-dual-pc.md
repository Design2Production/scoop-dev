# DP New DEVELOPMENT Installation for SureVision - Outdoor - Dual PC

## WINDOWS DEVELOPMENT SERVER - DO NOT DEPLOY TO THIS IN PRODUCTION

# Pre Installation
Ensure the Ethernet connection to the switch (connected to the internet) is made prior to installation, otherwise the automatic network configuration will throw an exception and abort the installation.

On Both PCs:

    1. Connect the longer Ethernet cable from the PCs to the swith to the left most port (when looking from the front of the PC)
    2. Connect the short Ethernet cable between the PCs to the right most port (when looking from the front of the PC)

# RemoteCommandRunner Installation

***The Remote command runner should ONLY be installed on the "Second" PC in a dual PC setup.***

If setting up a new PC B installtion follow [these](https://design2production.github.io/scoop-dev/new-rcr-install-surevision-outdoor-pc.html) instructions.

If upgrading an old PC B installation follow [these](https://design2production.github.io/scoop-dev/upgrade-rcr-install-surevision-outdoor-pc.html) instructions:

> During the installation script the IP Address of the unit will be reported. Note this IP address, as it is needed when installing the Device Proxy (see below).

# DeviceProxy Installation

1. Start Powershell as Administrator
<pre>
    1. Press the **Windows** key
    2. Type Powershell
    3. Right-Click on **Windows Powershell*** and select **"Run As Administrator"**
    4. Click on **Yes** when asked for permission
</pre>

2. Download the install script for a NEW installation
<pre>
Invoke-WebRequest -Uri https://design2production.github.io/scoop-dev/NewInstallDeviceProxy.ps1 -OutFile NewInstallDeviceProxy.ps1
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

3. Run the install script using the ***Unique-Device-Id*** for the unit:

<pre>.\NewInstallDeviceProxy.ps1 Production new dualPC Unique-Device-Id DPEMS-V2 10.10.10.3 10.1.10.101</pre> 

The arguments are as follows:
<pre>
      Production = which server to use: Staging | Production
          dualPC = InstallationType: singlePC|dualPC
Unique-Device-Id = Surevision Unique Device Id for this unit
        DPEMS-V2 = DPEMS Hardware Outdoor Units: DPEMS-V2
      10.10.10.3 = The Ip Address of the DPEMS-V2
     10.1.10.101 = The Ip Address of the second PC as noted down when installing the RemoteCommandRunner above
</pre>

> Ensure there are no errors reported during installation - it can take a long time to install, particularly on machines with slow or intermittant internet***