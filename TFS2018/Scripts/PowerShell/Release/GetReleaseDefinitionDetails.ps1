<# Script: GetReleaseDefinitionDetails
Author: Rehan Bhombal 
Date: 29/05/2019
Description: Script to list all Collections and Team Projects on the TFS Server. 
Usage: .\GetReleaseDefinitionDetails.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsCollectionUrl = 'https://tfs2018/tfs/Defaultollection',
    [Parameter(Mandatory=$true)][string] $tfsProjectName = '<ProjectName>'
)

$apiVersion = "api-version=4.1-preview" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

try
{
    $outputFile = "$PSScriptRoot\releases_$tfsProjectName.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }

    Write-Host "Collection Name:" "$coll " -NoNewline -ForegroundColor Magenta

    $tfsProjectReleasesApiUrl = "$($tfsCollectionUrl)/$($tfsProjectName)/_apis/release/definitions?$($apiversion)"
    $tfsProjectReleasesObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectReleasesApiUrl -ErrorAction Stop
    $releases = $tfsProjectReleasesObject.value

    $releasesCount = $releases.Count
    Write-Host "Build Count:" $releasesCount -BackgroundColor Magenta

    "{0}" -f "Collection URL: $tfsCollectionUrl`n" | Out-File -FilePath $outputFile
    "{0}`t{1}" -f "Project: $tfsProjectName", "Releases Count: $releasesCount`n" | Out-File -FilePath $outputFile -Append
    "{0}`t{1}`t{2}`t{3}" -f "Release ID", "Release Name", "Release Path", "Created By" | Out-File -FilePath $outputFile -Append

    foreach ($release in $releases)
    {
        Write-Host "Release Name:" $release.name -ForegroundColor Yellow
        # Writing into CSV file
        "{0}`t{1}`t{2}`t{3}" -f $release.id, $release.name, $release.Path, $release.createdBy.displayName | Out-File -FilePath $outputFile -Append 
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}