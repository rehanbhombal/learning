<# Script: GetTeamProjectsWithGUID
Author: Rehan Bhombal 
Date: 28/05/2019
Description: Script to list all team projects names and their ID's in a project collection 
Usage: .\GetTeamProjectsWithGUID.ps1 -tfsServerUrl https://tfs2018/tfs -tfsCollection DefaultCollection #>

<# Pararmeter for project collection name #>
[CmdletBinding()]
param
(
[Parameter(Position=0, Mandatory=$True)]
[String]$tfsServerUrl,
[Parameter(Position=1,Mandatory=$True)]
[String]$tfsCollection
)

$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

try
{    
    $response=$null
    $tfsCollectionUrl=$tfsServerUrl + "/" + $tfsCollection
    $tfsServerName = ([System.Uri]$tfsServerUrl).Host
    $outputFile = "$PSScriptRoot\projects_" + "$tfsServerName" + "_" + "$tfsCollection.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }
    "{0}`t{1}" -f "Project Name", "Id" | Out-File -FilePath $outputFile

    # List all the projects in the given collection
    $collectionUri="$tfsCollectionUrl/_apis/projects?api-version=2.3-preview&%24top=500"
    $response=Invoke-RestMethod -Method Get -UseDefaultCredentials -Uri $collectionUri
    $projectList=($response.value)

    # Get all team projects & Generate Report
    foreach ($project in $projectList) 
    {
        "{0}`t{1}" -f $project.name, $project.id | Out-File -FilePath $outputFile -Append
    }
}
catch
{    
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}