<# Script: AddADGroupToTFSGroup
Author: Rehan Bhombal 
Date: 01/08/2019
Description: Script to add AD Group to TFS Group for every Team Project per collection on the TFS Server. 
Usage: .\AddADGroupToTFSGroup.ps1 'https://tfs2018/tfs' '<ADGROUPNAME>' 'Readers'#>

param
(
    [Parameter(Mandatory=$false)][string] $tfsServer = 'https://tfs2018/tfs'
)

$apiVersion = "api-version=2.0" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

# Get Collections
function GetCollections
{
    param
    (
        [Parameter(Mandatory=$true)][string] $tfsServer
    )
    try
    {
        $tfsServerApiUrl = $tfsServer + '/_apis/projectCollections'
        #Write-Host $tfsServerApiUrl
        $tfsServerObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsServerApiUrl -ErrorAction Stop
        #Write-Host $tfsServerObject
        $collections = $tfsServerObject.value.name
        #Write-Host $collections
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $collections
}

# Get Projects
function GetProjects
{
    param
    (
        [Parameter(Mandatory=$true)][string] $collection
    )
    try
    {
        $tfsProjectsApiUrl = "$($tfsServer)/$($collection)/_apis/projects/?$($apiversion)&`$top=500"
        #Write-Host $tfsProjectsApiUrl
        $tfsProjectObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectsApiUrl -ErrorAction Stop
        #Write-Host $tfsProjectObject
        $projects = $tfsProjectObject.value.name
        Write-Host $projects
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $projects
}

try
{
    $colls = GetCollections -tfsServer $tfsServer
    foreach($coll in $colls)
    {
        $outputFile = "$PSScriptRoot\projects_$coll.csv"
        # Remove existing output file
        if(Test-Path $outputFile)
        {
            Remove-Item $outputFile
        }

        "{0}" -f "Collection: $coll`n" | Out-File -FilePath $outputFile
        "{0}" -f "Projects" | Out-File -FilePath $outputFile -Append

        Write-Host "Collection Name:" "$coll " -NoNewline -ForegroundColor Magenta

        $projs = GetProjects -collection $coll
        Write-Host $projs
        $projectCount = $projs.Count
        Write-Host "Project Count:" $projectCount -BackgroundColor Magenta

        foreach ($proj in $projs)
        {
            Write-Host "Project Name:" $proj -ForegroundColor Yellow
            # Writing into CSV file
            "{0}" -f $proj | Out-File -FilePath $outputFile -Append
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}