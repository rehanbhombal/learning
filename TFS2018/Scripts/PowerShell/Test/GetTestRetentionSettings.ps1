<# Script: GetTestRetentionSettings
Author: Rehan Bhombal 
Date: 03/06/2019
Description: Script to list Test Retention settings for all the Team Projects on the TFS Server. 
Usage: .\GetTestRetentionSettings.ps1 'https://tfs2018/tfs/' 'DefaultCollection' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsServerUrl = 'https://tfs2018/tfs',
    [Parameter(Mandatory=$true)][string] $tfsCollectionName = 'DefaultCollection'
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
    $outputFile = "$PSScriptRoot\settings_$tfsCollectionName.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }
    "{0}" -f "$($tfsServerUrl)/$($tfsCollectionName)`n" | Out-File -FilePath $outputFile
    "{0}`t{1}`t{2}" -f "Project","AutomatedTestRetentionDays","ManualTestRetentionDays" | Out-File -FilePath $outputFile -Append

    # List all projects in the collection
    $tfsCollectionUrl = "$($tfsServerUrl)/$($tfsCollectionName)/_apis/projects?$($apiversion)&%24top=500"
    $projectsResponse = Invoke-RestMethod -Method Get -UseDefaultCredentials -Uri $tfsCollectionUrl
    $projects = ($projectsResponse.value).name

    # Get retention settings for each project
    foreach ($project in $projects)
    {
        [String] $ATRD = $null
        [String] $MTRD = $null
        $settingsResponse = $null

        $testRetentionSettingsApiUrl = "$($tfsServerUrl)/$($tfsCollectionName)/$($project)/_apis/test/resultretentionsettings"
        $settingsResponse = Invoke-RestMethod -Method Get -UseDefaultCredentials -Uri $testRetentionSettingsApiUrl
        $ATRD = ($settingsResponse).automatedResultsRetentionDuration
        $MTRD = ($settingsResponse).manualResultsRetentionDuration

        if($ATRD -eq "-1")
        {
            $ATRD = "Never Delete"
        }
        if($MTRD -eq "-1")
        {
            $MTRD = "Never Delete"
        }
        # Writing into CSV file
        "{0}`t{1}`t{2}" -f $project, $ATRD, $MTRD | Out-File -FilePath $outputFile -Append 
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}