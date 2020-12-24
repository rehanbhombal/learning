<# Script: GetBuildDefinitionDetails
Author: Rehan Bhombal 
Date: 29/05/2019
Description: Script to list all Collections and Team Projects on the TFS Server. 
Usage: .\GetBuildDefinitionDetails.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsCollectionUrl = 'https://tfs2018/tfs/Defaultollection',
    [Parameter(Mandatory=$true)][string] $tfsProjectName = '<ProjectName>'
)

$apiVersion = "api-version=4.1" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

try
{
    $outputFile = "$PSScriptRoot\builds_$tfsProjectName.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }

    $tfsProjectBuildsApiUrl = "$($tfsCollectionUrl)/$($tfsProjectName)/_apis/build/definitions?$($apiversion)"
    $tfsProjectBuildsObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectBuildsApiUrl -ErrorAction Stop
    $builds = $tfsProjectBuildsObject.value

    $buildCount = $builds.Count
    Write-Host "Build Count:" $buildCount -BackgroundColor Magenta

    "{0}" -f "Collection URL: $tfsCollectionUrl`n" | Out-File -FilePath $outputFile
    "{0}`t{1}" -f "Project: $tfsProjectName", "Build Count: $buildCount`n" | Out-File -FilePath $outputFile -Append
    "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f "Build ID", "Build Name", "Build Path", "Queue Name", "Pool Name", "Queue Staus", "Project Name" | Out-File -FilePath $outputFile -Append

    foreach ($build in $builds)
    {
        Write-Host "Build Name:" $build.name -ForegroundColor Yellow
        # Writing into CSV file
        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}`t{6}" -f $build.id, $build.name, $build.Path, $build.queue.name, $build.queue.pool.name, $build.queueStatus, $build.project.name | Out-File -FilePath $outputFile -Append 
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}