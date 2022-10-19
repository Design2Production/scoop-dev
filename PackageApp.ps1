$application = $args[0]
$repo = 'scoop-dev'

Switch ($application)
{
    'DeviceProxy' {}
    'RemoteCommandRunner' {}
    default
    {
        Write-Output 'applicaiton needs to be specified DeviceProxy | RemoteCommandRunner'
        exit 1
    }
}

Switch ($repo)
{
    'scoop-dev' {}
    'scoop' {}
    default
    {
        Write-Output 'repo needs to be specified scoop | scoop-dev'
        exit 1
    }
}

$version = (Get-Item ..\WindowsBuilds\$application\$application.dll).VersionInfo.FileVersion

if ( [string]::IsNullOrEmpty($version) -eq 'True' )
{
    Write-Output "$application version not detected"
    exit
}

Write-Output "Packaging $($application)_$version..."

Compress-Archive -Path "..\WindowsBuilds\$application" -DestinationPath "docs\windows\dpems\$($application)_$version.zip" -Force

$fileHash = (Get-FileHash -Path .\docs\windows\dpems\$($application)_$version.zip).hash

# Create $application.json
Set-Content -Path "$application.json" -Value "{
    `"version`": `"$version`",
    `"url`": `"https://design2production.github.io/$repo/windows/dpems/$($application)_$version.zip`",
    `"extract_dir`": `"$application`",
    `"bin`": `"$application.exe`",
    `"hash`": `"$fileHash`",
    `"checkver`": {
        `"url`": `"https://design2production.github.io/$repo/$($application)Versions.json`",
        `"jp`": `"$.versions[?(@.displayName == '$application - Latest')].version`"
    },
    `"autoupdate`": {
        `"url`": `"https://design2production.github.io/$repo/windows/dpems/$($application)_`$version.zip`"
    }
}" -PassThru

# Create $applicationVersions.json

$outputFilename = ".\docs\$($application)Versions.json"
$applicationFiles = Get-ChildItem ".\docs\windows\dpems\$application*" | Sort-Object -Descending
$latestFileString = ' - Latest'

Set-Content -Path $outputFilename -Value "{
    `"versions`": [" -PassThru
foreach ($f in $applicationFiles)
{
    if ($f -eq $applicationFiles[-1])
    {
        $comma = ''
    }
    else
    {
        $comma = ','
    }
    $fileVersion = $f.Name.replace("$($application)_",'')
    $fileVersion = $fileVersion.replace('.zip','')
    $fileDate = Get-Date -Date ([DateTime]$($f.CreationTime)).ToUniversalTime() -Format 'yyyy-MM-ddThh:mm:ss:fffZ'
    $fileHash = (Get-FileHash -Path $($f.FullName)).hash
    Add-Content -Path $outputFilename -Value "        {
            `"displayName`": `"$application$latestFileString`",
            `"version`": `"$fileVersion`",
            `"url`": `"https://design2production.github.io/$repo/windows/dpems/$($application)_$fileVersion.zip`",
            `"hash`": `"$fileHash`",
            `"releasedate`": `"$fileDate`"
        }$comma" -PassThru
    $latestFileString = ''
}
Add-Content -Path $outputFilename -Value '    ]
}' -PassThru
