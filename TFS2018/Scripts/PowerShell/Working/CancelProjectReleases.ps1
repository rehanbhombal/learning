<# Script: CancelProjectReleases
Author: Rehan Bhombal 
Date: 23/03/2020
Description: Script to list all Collections and Team Projects on the TFS Server. 
Usage: .\GetBuildDefinitionDetails.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsServer = "https://tfs2018/tfs",
    [Parameter(Mandatory=$true)][string] $collection = "DefaultCollection",
    [Parameter(Mandatory=$true)][string] $project = "<ProjectName>"
)

$apiVersion = "api-version=4.1-preview" 
$logFile = "$PSScriptRoot\log.txt"
$top = "&`$top=100"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

$tfsUrl = "$tfsServer/$collection/$project" # TFS Base URL
$ReleaseDefsUrl = "$tfsUrl/_apis/release/definitions?$apiVersion" # TFS release definitions URL
$ReleasesUrl = "$tfsUrl/_apis/release/releases"  #TFS Releases URL
$ReleaseDefs = (Invoke-RestMethod -Uri ($ReleaseDefsUrl) -Method GET -UseDefaultCredentials).value | Select id,name # get all release Defs
foreach($ReleaseDef in $ReleaseDefs)
{
    $releaseDefId = $ReleaseDef.id
    $command = "$($ReleasesUrl)?definitionId=$($releaseDefId)&$apiVersion$top"
    Write-Host $command
}
# https://tfs2018/tfs/DefaultCollection/<ProjectName>/_apis/release/releases?api-version=4.1-preview&$top=200