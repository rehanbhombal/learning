<# Script: GetTaskUsage.ps1
Author: Rehan Bhombal 
Date: 28/04/2020
Description: Script to list all Build & Release where a specific task type is used. 
Usage: .\GetTaskUsage.ps1 -tfsServer 'https://tfs2018/tfs/' -collectionName 'DefaultCollection' -taskSearchString "*Copy*" #>

param
(
    $tfsServer = 'https://tfs2018/tfs/',
    $collectionName = 'DefaultCollection',
    $taskSearchString = "*Copy*"
)

$apiVersionTag = "api-version=4.1"
[string]$date = "{0:yyyy.MM.dd}" -f (get-date)
$FilePrefix = ($PSScriptRoot+"\"+$PSCommandPath.split('\.')[-2] )  #shared common filename path without extension
$Global:PathToExceptionsLog = $FilePrefix+".err.log" #errors log
$Global:logFile = "$FilePrefix.ActivityLog.log"

function GetProjects
{
    param (
        [Parameter(Mandatory=$true)][string]$collectionName
        )
    # Construct the Get list of team projects url
    $getProjectsUrl = "$($tfsServer)/$($collectionName)/_apis/projects/?$($apiVersionTag)&`$top=1000"
    Write-Debug "Get Projects for $getProjectsUrl"
    # Call the REST API using Invoke-RestMethod. -UseDefaultCredentials for using windows authentication
    $json = Invoke-RestMethod -UseDefaultCredentials -uri $getProjectsUrl
    $formatedJson =  $json | Format-List
    # Write-Debug $formatedJson
    return $json.value | sort -Property name
}

function GetBuildDefinitions
{
    param ( 
        [Parameter(Mandatory=$true)][string]$collectionName,
        [Parameter(Mandatory=$true)][string]$projectName
        )

    $definitionsOverviewUrl = "$tfsServer/$collectionName/$projectName/_apis/build/definitions?$($apiVersionTag)"
    Write-Debug "Getting Build Definitions for $definitionsOverviewUrl"
    $definitionsOverviewResponse = Invoke-RestMethod -UseDefaultCredentials -Uri $definitionsOverviewUrl
    return $definitionsOverviewResponse.value
}

$projects = GetProjects -collectionName $collectionName

foreach ($project in $projects)
{
    #Write-Host $project.name
    $definitions = GetBuildDefinitions -collectionName $collectionName -projectName $project.name
    foreach ($definition in $definitions | where { $_.type -ne "xaml" } ) #check only new builds
     {
            $definitionDetails = Invoke-RestMethod -UseDefaultCredentials -uri $definition.url
            $foundTasks = $definitionDetails.process.phases.steps | where  { $_.displayName -like $taskSearchString} #-and $_.enabled -and $_.inputs.ArtifactType -eq "Container"}  # { $_.id -in ($watchedTasks | % { $_.id })}
            if (($foundTasks | Measure-Object).Count -gt 0)
            {
                try
                {
                   $item = New-Object PsObject -Property @{ Collection = $collectionName; Project = $definitionDetails.project.name ; BuildDef = $definitionDetails.name ; BuildUri = $definitionDetails._links.self.href};
                   $item | Export-Csv  "$($FilePrefix)_$($date).out.csv" -Append -Encoding UTF8 -NoTypeInformation
                   #$watched += $item;
                }
                catch [Exception]
                {
                    $_.Exception | Out-File $PathToExceptionsLog -Append
                }
            }
     } #end  build def
}