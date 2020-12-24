<# Script: GetCollectionsAndProjects
Author: Rehan Bhombal 
Date: 28/05/2019
Description: Script to list all Collections and Team Projects on the TFS Server. 
Usage: .\GetCollectionsAndProjects.ps1 'https://tfs2018/tfs' #>

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
        Write-Host "Collection Name:" "$coll " -NoNewline -ForegroundColor Magenta

        $projs = GetProjects -collection $coll
        Write-Host $projs
        $projectCount = $projs.Count
        Write-Host "Project Count:" $projectCount -BackgroundColor Magenta

        foreach ($proj in $projs)
        {
            Write-Host "Project Name:" $proj -ForegroundColor Yellow
            $tfsUrl = "$tfsServer/$coll/$proj" # TFS Base URL
            $BuildDefsUrl = "$tfsUrl/_apis/build/definitions?api-version=2.0" # TFS build definitions URL
            $BuildsUrl = "$tfsUrl/_apis/build/builds"  #TFS Builds URL

            $Builds = (Invoke-RestMethod -Uri ($BuildDefsUrl) -Method GET -UseDefaultCredentials).value | Select id,name # get all builds 
            #for filtering use : |  Where-Object {$_.name -like "*Your Pattern*"}

            foreach($Build in $Builds)
            {
                $command = "$($BuildsUrl)?api-version=3.2-preview.3&resultFilter=inprogress&definitions=$($Build.id)&queryOrder=finishTimeDescending"

                $Ids = (((Invoke-RestMethod -Method Get -Uri $command -UseDefaultCredentials).value) | where status -like "*notStarted*").id # get waiting builds id's

                foreach($id in $Ids)
                {
                        $uri =  "$($BuildsUrl)/$($id)?api-version=2.0" # TFS URI
                        $body = '{"status":4}' # body 
                        $result = Invoke-RestMethod -Method Patch -Uri $uri -UseDefaultCredentials -ContentType 'application/json' -Body $body -Verbose #cancel  build
                }
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