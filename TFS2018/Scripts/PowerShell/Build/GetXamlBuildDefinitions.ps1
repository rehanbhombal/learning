<# Script: GetXamlBuildDefinitions
Author: Rehan Bhombal 
Date: 07/06/2019
Description: Script to list all Team Projects using Xaml build definitions. 
Usage: .\GetXamlBuildDefinitions.ps1 'https://tfs2018/tfs' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsServer = 'https://tfs2018/tfs'
)

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
        $tfsServerObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsServerApiUrl -ErrorAction Stop
        $collections = $tfsServerObject.value.name
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
        $tfsProjectObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectsApiUrl -ErrorAction Stop
        $projects = $tfsProjectObject.value.name
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $projects
}

# Get XAML Build Definitions
Function GetXamlBuildDefinitions
{
# This function gets build definitions (xaml) from project
 param( 
 	    [Parameter(Mandatory=$true)][string]$tfsServer,
        [Parameter(Mandatory=$true)][string]$collection,
        [Parameter(Mandatory=$true)][string]$project
      )
    begin{}
    process
    {
        try
        {
            $Uri = $tfsServer + "/"+ $collection + "/"+ $project +"/_apis/build/definitions?api-version=2.0"
            $releaseresponse = Invoke-Webrequest -Method Get -UseDefaultCredentials -ContentType application/json -Uri $Uri
            #getting build definitions
            $buildDefinitions = ($releaseresponse | ConvertFrom-Json).value | Where {$_.Type -like "xaml"} 
        }
        catch
        {
            $_.Exception.Message
            $_ | Out-File -FilePath $logFile -Append
            exit
        }
        return $buildDefinitions
    }
    end{}
}

# Get Buid Definition Details
function GetBuildDefinitionDetails
{
# This function gets build properties

 param( 
 	[Parameter(Mandatory=$true)][string]$tfsServer,
    [Parameter(Mandatory=$true)][string]$collection,
    [Parameter(Mandatory=$true)][string]$project,
    [Parameter(Mandatory=$true)][string]$buildId
      )
    begin
    {}
    process
    {
        try
        {
            $Uri = $tfsServer + "/"+$collection  +"/"+$project  +"/_apis/build/definitions/"+$buildId+"?api-version=2.0"
            $bd = Invoke-Webrequest -Method Get -UseDefaultCredentials -ContentType application/json -Uri $Uri
        }
        catch
        {
            $_.Exception.Message
            $_ | Out-File -FilePath $logFile -Append
            exit
        }
        return $build = ($bd | ConvertFrom-Json)
    }
    end{}
}

try
{
    $timestamp = Get-Date -UFormat %Y%m%d%H%M%S

    $logFile = "$PSScriptRoot\errorLog-" + $timestamp + ".csv"
    # Remove existing log  file
    if(Test-Path $logFile)
    {
        Remove-Item $logFile
    }

    $collections = GetCollections -tfsServer $tfsServer

    #We can exclude Archived and Test collections 
    $excludedCollections = @("Archive","Training")

    $buildDefNumber = 0

    foreach($collection in $($collections | Where {$excludedCollections -notcontains $_} | Sort))
    {
        $projects = GetProjects -collection $collection | Sort Name #| Where {$_.Name -like "<ProjectName>"}}

        foreach($project in $projects)
        {
            Write-Host "Project: "$project
            [array]$objlist = @()	
            [array]$outputResult = $null
            #geting XAML build definitions lists
            $xamlBuildDefinitions = GetXamlBuildDefinitions -tfsServer $tfsServer -collection $collection -project $project
            Write-Host "Build Count: "$xamlBuildDefinitions.Count

            #increasing the number of xaml builds in TFS
            $buildDefNumber += $xamlBuildDefinitions.Count

            foreach($build in $xamlBuildDefinitions)
            {
                $build = GetBuildDefinitionDetails $tfsServer $collection $project $build.Id
                if($build.queueStatus)
                {
                    $queueStatus = $build.queueStatus
                }
                else
                {
                    $queueStatus = "Enabled"
                }
                $properties = [ordered]@{
                Collection = $collection
                ProjectName = $project
                BuildName = $build.name
				BuildId = $build.id
                Type = $build.repository.type
                Status = $queueStatus
                Trigger = $build.triggerType
                }
                $object =  New-Object -TypeName PSObject -Property $properties	
                [array]$objlist += $object	
            }
            if(($objlist | Measure-Object).Count -gt 0)
            {
                $fileName = "$PSScriptRoot\Results-" + $timestamp + ".csv"
                $objlist | Export-Csv -NoTypeInformation -Append -Path $fileName
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