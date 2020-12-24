<# Script: GetTeamsAndMembers
Author: Rehan Bhombal 
Date: 08/07/2019
Description: Script to list all TFS Project Teams and its members. 
Usage: .\GetTeamsAndMembers.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' #>

param
(
    [Parameter(Mandatory=$true)][string] $collectionURL,
    [Parameter(Mandatory=$true)][string] $tfsProject
)

$apiVersion = "api-version=4.1-preview.2" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

# Get Teams
function GetTeams
{
    param
    (
        [Parameter(Mandatory=$true)][string] $collectionURL,
        [Parameter(Mandatory=$true)][string] $tfsProject
    )
    try
    {
        $tfsProjectTeamsApiUrl = "$($collectionURL)/_apis/projects/$tfsProject/teams?$($apiversion)&`$top=500"
        #Write-Host $tfsProjectTeamsApiUrl
        $tfsProjectTeamsObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsProjectTeamsApiUrl -ErrorAction Stop
        #Write-Host $tfsProjectTeamsObject
        $teams = $tfsProjectTeamsObject.value.name
        #Write-Host $teams
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $teams
}

# Get Team Members
function GetTeamMembers
{
    param
    (
        [Parameter(Mandatory=$true)][string] $team
    )
    try
    {
        $tfsTeamMembersApiUrl = "$($collectionURL)/_apis/projects/$tfsProject/teams/$team/members?$($apiversion)&`$top=500"
        #Write-Host $tfsTeamMembersApiUrl
        $tfsTeamMembersObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsTeamMembersApiUrl -ErrorAction Stop
        #Write-Host $tfsTeamMembersObject
        $members = $tfsTeamMembersObject.value.identity.uniqueName
        #Write-Host $members
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $members
}

try
{
    $outputFile = "$PSScriptRoot\project_$tfsProject.csv"
    Write-Host $outputFile
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }
    "{0}" -f "Project: $tfsProject`n" | Out-File -FilePath $outputFile
    $teams = GetTeams $collectionURL $tfsProject
    #$teamsCount = $teams.Count
    #Write-Host "Teams Count:" $teamsCountt -BackgroundColor DarkGreen
    foreach($team in $teams)
    {
        
        "{0}" -f "Team Name: $team" | Out-File -FilePath $outputFile -Append

        Write-Host "Team Name:" "$team`n" -NoNewline -ForegroundColor Magenta
        
        $teamMembers = GetTeamMembers -team $team

        foreach ($member in $teamMembers)
        {
            #Write-Host "Member:" $member -ForegroundColor Yellow
            # Writing into CSV file
            "{0}" -f $member | Out-File -FilePath $outputFile -Append
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}