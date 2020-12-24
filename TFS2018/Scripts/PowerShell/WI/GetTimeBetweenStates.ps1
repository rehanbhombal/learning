<# Script: GetTimeBetweenStates.ps1
Author: Rehan Bhombal 
Date: 15/05/2020
Description: Script to get the time required from one state to another state where the state field is a custom field. 
Usage 1: .\GetTimeBetweenStates.ps1 -tfsCollectionURL 'https://tfs2018/tfs/DefaultCollection' -tfsProjectName '<ProjectName>' -tfsWiType '<WorkItemType>' -fieldName '<FieldName>' -fromStatus '<FromStatus>' -toStatus '<ToStatus>' -dataFrom '01/01/2020'

Usage 2: .\GetTimeBetweenStates.ps1 -tfsCollectionURL 'https://tfs2018/tfs/DefaultCollection' -tfsProjectName '<ProjectName>' -tfsWiType '<WorkItemType>' -fieldName '<FieldName>' -fromStatus '<FromStatus>' -toStatus '<ToStatus>' -dataFrom '01/01/2020'
#>

param
(
    [Parameter(Mandatory=$true)][string] $tfsCollectionURL = 'https://tfs2018/tfs/DefaultCollection',
    [Parameter(Mandatory=$true)][string] $tfsProjectName = '<ProjectName>',
    [Parameter(Mandatory=$true)][string] $tfsWiType = '<WorkItemType>',
    [Parameter(Mandatory=$true)][string] $fieldName = '<FieldName>',
    [Parameter(Mandatory=$true)][string] $fromStatus = '<FromStatus>',
    [Parameter(Mandatory=$true)][string] $toStatus = '<ToSatus>',
    [Parameter(Mandatory=$true)][string] $dataFrom = '01/01/2020'
)

$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

try
{
    $apiVersion = "api-version=4.1"
    $url = $tfsCollectionURL + '/_apis/wit/wiql?' + $apiVersion
    $WIQL_query = "Select [System.Id], [System.Title] From WorkItems Where [System.WorkItemType] = '" + $tfsWiType + "' AND [System.TeamProject] = '" + $tfsProjectName + "' AND [System.CreatedDate] >= '" + $dataFrom + "' order by [System.CreatedDate] asc"
    $body = @{ query = $WIQL_query }
    $bodyJson=@($body) | ConvertTo-Json
    $response = Invoke-RestMethod -Uri $url -UseDefaultCredentials -Method Post -ContentType "application/json" -Body $bodyJson
    $workitems = $response.workItems

    $outputFile = "$PSScriptRoot\workitems_$tfsProjectName.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }
     "{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f "Id", "Title", "Days", "Hours", "Minutes", "Seconds" | Out-File -FilePath $outputFile

    foreach($workitem in $workitems)
    {
        $wId = $workitem.id
        $wiRevisionsUrl = $tfsCollectionURL + '/_apis/wit/workItems/' + $wId + '/revisions?' + $apiVersion
        $revisions = Invoke-RestMethod -Uri $wiRevisionsUrl -Method Get -UseDefaultCredentials -ErrorAction Stop
        $fromStateDates =@()
        $toStateDates =@()
        foreach($revision in $revisions.value | where {$_.fields.$fieldName -eq $fromStatus}) 
        {
            if($revision.fields.$fieldName -eq $fromStatus)
            {
                $fromStateDates += $revision.fields.'System.ChangedDate'
            }
        }
        foreach($revision in $revisions.value | where {$_.fields.$fieldName -eq $toStatus})
        {
            if($revision.fields.$fieldName -eq $toStatus)
            {
                $toStateDates += $revision.fields.'System.ChangedDate'
            }
        }
        if($fromStateDates -ne "" -and $toStateDates -ne "")
        {
            $workItemUrl = $tfsCollectionURL + "/_apis/wit/workitems/" + $wId + "?" + $apiVersion
            $wiResponse = Invoke-RestMethod -Method Get -Uri $workItemUrl -UseDefaultCredentials
            $fromStateFirstDate  = $fromStateDates | Select-Object -First 1
            $toStateFirstDate  = $toStateDates | Select-Object -First 1
            if($toStateFirstDate -ge $fromStateFirstDate)
            {
                $timeRequired = New-TimeSpan -Start $fromStateFirstDate -End $toStateFirstDate 
                "{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f $wId, $wiResponse.fields.'System.Title', $timeRequired.Days, $timeRequired.Hours, $timeRequired.Minutes, $timeRequired.Seconds | Out-File -FilePath $outputFile -Append
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