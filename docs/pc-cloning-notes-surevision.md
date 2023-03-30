# DP PC Cloning Notes - Surevision

You can follow the installation proceedure for your A and B PCs and then clone the images for faster production deployment, however, the ***deviceID*** filed will then be the same on the new images.

After cloning, on the A PC, the ***C:\ProgramData\DP\DeviceProxy\setting.json*** file must be edited and the ***deviceId*** field must be made unique.

The contents of the file will look like the following:
<pre>
{
  "port": "COM6",
  "daughterBoardPort": "COM7"
  "deviceAddress": "http://10.10.10.3:8000",
  "deviceId": "UNIQUE-DEVICE-ID",
  "LcdTurnOnSchedule": "",
  "LcdTurnOffSchedule": "",
  "DeviceInfoPollerScheduler": "* * * * *",
  "enableRemoteCommand": "true",
  "secondPcIpAddress": "192.168.0.200",
}
</pre>

Please ensure you don't accidentally remove or change any punctuation. Only change the value of the deviceId inside the double quotes "UNIQUE-DEVICE-ID".