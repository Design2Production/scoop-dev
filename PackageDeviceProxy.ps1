$version = (Get-Item ..\WindowsBuilds\DeviceProxy\DeviceProxy.dll).VersionInfo.FileVersion

if ( [string]::IsNullOrEmpty($version) -eq "True" )
{
    Write-Output "DeviceProxy version not detected"
    exit
}

Write-Output "Packaging DeviceProxy_$($version)..."

Compress-Archive -Path ..\WindowsBuilds\DeviceProxy -DestinationPath docs\windows\dpems\DeviceProxy_$version.zip

$fileHash = (Get-FileHash -Path .\docs\windows\dpems\DeviceProxy_$version.zip).hash

# Create DeviceProxy.json
Set-Content -Path DeviceProxy.json -Value "{
    `"version`": `"$version`",
    `"url`": `"https://design2production.github.io/scoop-dev/windows/dpems/DeviceProxy_$version.zip`",
    `"extract_dir`": `"DeviceProxy`",
    `"bin`": `"DeviceProxy.exe`",
    `"hash`": `"$fileHash`",
    `"checkver`": {
        `"url`": `"https://design2production.github.io/scoop-dev/device-proxy-versions.json`",
        `"jp`": `"$.versions[?(@.displayName == 'DeviceProxy - Latest')].version`"
    },
    `"autoupdate`": {
        `"url`": `"https://design2production.github.io/scoop-dev/windows/dpems/DeviceProxy_`$version.zip`"
    }
}" -PassThru

# Create device-proxy-versions.json

$outputFilename = ".\docs\device-proxy-versions.json"
$proxyFiles = Get-ChildItem ".\docs\windows\dpems\" | Sort-Object -Descending
$latestFileString = " - Latest"

Set-Content -Path $outputFilename -Value "{
    `"versions`": [" -PassThru
foreach ($f in $proxyFiles)
{
    $fileVersion = $f.Name.replace("DeviceProxy_","")
    $fileVersion = $fileVersion.replace(".zip","")
    $fileDate = Get-Date -Date ([DateTime]$($f.CreationTime)).ToUniversalTime() -Format "yyyy-MM-ddThh:mm:ss:fffZ"
    $fileHash = (Get-FileHash -Path $($f.FullName)).hash
    Add-Content -Path $outputFilename -Value "        {
            `"displayName`": `"DeviceProxy$latestFileString`",
            `"version`": `"$fileVersion`",
            `"url`": `"https://design2production.github.io/scoop-dev/windows/dpems/DeviceProxy_$fileVersion.zip`",
            `"hash`": `"$fileHash`",
            `"releasedate`": `"$fileDate`"
        }," -PassThru
    $latestFileString = ""
}
Add-Content -Path $outputFilename -Value "    ]
}" -PassThru
