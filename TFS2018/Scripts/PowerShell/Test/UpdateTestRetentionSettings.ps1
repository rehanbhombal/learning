<# Script: UpdateTestRetentionSettings
Author: Rehan Bhombal 
Date: 06/05/2020
Description: Script to update Test Retention settings for all the Team Projects in the collection on the TFS Server. 
This script sets the automated test retention settings to 30 days and manual test retention settings to 365 days.
If the automated and manual test retention days are already below the default values no changes are made.
Usage: .\UpdateTestRetentionSettings.ps1 'https://tfs2018/tfs/' 'Ettsak' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsServerUrl = 'https://tfs2018/tfs',
    [Parameter(Mandatory=$true)][string] $tfsCollectionName = 'Ettsak'
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
    # List all projects in the collection
    $tfsCollectionUrl = "$($tfsServerUrl)/$($tfsCollectionName)/_apis/projects?$($apiversion)&%24top=500"
    $projectsResponse = Invoke-RestMethod -Method Get -UseDefaultCredentials -Uri $tfsCollectionUrl
    $projects = ($projectsResponse.value).name

    # Get retention settings for each project
    foreach ($project in $projects)
    {
        $response=$null
        $projectUri="$($tfsServerUrl)/$($tfsCollectionName)/$($project)/_apis/test/resultretentionsettings"
        $response=Invoke-RestMethod -Method Get -UseDefaultCredentials -Uri $projectUri
        [int]$ATRD=($response).automatedResultsRetentionDuration
        [int]$MTRD=($response).manualResultsRetentionDuration
        $a=$ATRD
        $m=$MTRD
        
        if (($ATRD -gt 0) -and ($MTRD -gt 0)) 
        {
            if(($ATRD -lt 30) -and ($MTRD -lt 365))
            {
                Write-Output "`nAlready has less values than default settings, Setting not updated for the project : $project`n"
            }
            elseif(($ATRD -eq 30) -and ($MTRD -eq 365))
            {
                Write-Output "`nAlready has default settings, Setting not updated for the project : $project`n"
            }
            else
            {
                if ($ATRD -gt 30) 
                {
                    $a=30
                }
                if ($MTRD -gt 365) 
                {
                    $m=365
                }       
                $body=@{
                "automatedResultsRetentionDuration"=$a
                "manualResultsRetentionDuration"=$m
                }
                $json = $body | Convertto-JSON
                $URI="$projectUri"+"?$apiVersion"
                Invoke-RestMethod -Method PATCH -Uri $URI -Body $json -ContentType 'application/json' -UseDefaultCredentials
                Write-Output "Setting updated for the project : $project`n`n"
            }  
        }
        elseif (($ATRD -gt 0) -and ($MTRD -lt 0))
        {
            $m = 365
            if ($ATRD -gt 30) 
            {
                $a=30
            }       
            $body=@{
            "automatedResultsRetentionDuration"=$a
            "manualResultsRetentionDuration"=$m
            }
            $json = $body | Convertto-JSON
            $URI="$projectUri"+"?$apiVersion"
            Invoke-RestMethod -Method PATCH -Uri $URI -Body $json -ContentType 'application/json' -UseDefaultCredentials
            Write-Output "Setting updated for the project : $project`n`n"
        }
        elseif (($ATRD -lt 0) -and ($MTRD -gt 0))
        {
            $a = 30
            if ($MTRD -gt 365) 
            {
                $m=365
            }       
            $body=@{
            "automatedResultsRetentionDuration"=$a
            "manualResultsRetentionDuration"=$m
            }
            $json = $body | Convertto-JSON
            $URI="$projectUri"+"?$apiVersion"
            Invoke-RestMethod -Method PATCH -Uri $URI -Body $json -ContentType 'application/json' -UseDefaultCredentials
            Write-Output "Setting updated for the project : $project`n`n"
        }
        elseif (($ATRD -lt 0) -and ($MTRD -lt 0)) 
        {
            $a = 30
            $m = 365       
            $body=@{
            "automatedResultsRetentionDuration"=$a
            "manualResultsRetentionDuration"=$m
            }
            $json = $body | Convertto-JSON
            $URI="$projectUri"+"?$apiVersion"
            Invoke-RestMethod -Method PATCH -Uri $URI -Body $json -ContentType 'application/json' -UseDefaultCredentials
            Write-Output "Setting updated for the project : $project`n`n"  
        } 
        else 
        {
            Write-Output "`nSomething went wrong, Setting not updated for the project : $project`n"  
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}