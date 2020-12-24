<# Script: GetTFSGroups
Author: Rehan Bhombal 
Date: 20/08/2019
Description: Script to get TFS project groups. 
Usage: .\GetTFSGroups.ps1 'https://tfs2018/tfs'#>

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
        #Write-Host $projects
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $projects
}

# Get Team Project Groups
function GetTeamProjectGroups
{
    param
    (
        [Parameter(Mandatory=$true)][string] $collection,
        [Parameter(Mandatory=$true)][string] $project
    )
    try
    {
        $tfsProjectGroupsApiUrl = "$($tfsServer)/$($collection)/$($project)/_api/_identity/ReadScopedApplicationGroupsJson?__v=5"
        #Write-Host $tfsProjectGroupsApiUrl
        $tfsProjectGroupObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectGroupsApiUrl -ErrorAction Stop
        #Write-Host $tfsProjectGroupObject
        $projectGroups = $tfsProjectGroupObject.identities
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    #Write-Host $projectGroups
    return $projectGroups
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

        "{0}`t{1}`t{2}" -f "Project Name","Group Name","Group Type" | Out-File -FilePath $outputFile # -Append

        Write-Host "Collection Name:" "$coll " -NoNewline -ForegroundColor Magenta

        $projs = GetProjects -collection $coll
        $projectCount = $projs.Count
        Write-Host "Project Count:" $projectCount -BackgroundColor Magenta

        foreach ($proj in $projs)
        {
            $groups = GetTeamProjectGroups -collection $coll -project $proj
            # Writing into CSV file
            foreach ($group in $groups)
            {
                
                "{0}`t{1}`t{2}" -f $proj, $group.FriendlyDisplayName, $group.IdentityType | Out-File -FilePath $outputFile -Append
                
            }
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}