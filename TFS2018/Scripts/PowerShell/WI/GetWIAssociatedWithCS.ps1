<# Script: GetWIAssociatedWithCS.ps1
Author: Rehan Bhombal 
Date: 21/08/2019
Description: Script to list all Work items associated with changesets for path. 
Usage: .\GetWIAssociatedWithCS.ps1 'https://tfs2018/tfs/DefaultCollection' '$/<ProjectName>/MyWebApp' #>

param
(
    [Parameter(Mandatory=$false)][string] $tfsCollectionURL = 'https://tfs2018/tfs/DefaultCollection',
    [Parameter(Mandatory=$false)][string] $tfvcPath = '$/<ProjectName>/MyWebApp'
)

$apiVersion = "api-version=4.1" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

# Get Changesets
function GetChangesets
{
    param
    (
        [Parameter(Mandatory=$true)][string] $tfsCollectionURL,
        [Parameter(Mandatory=$true)][string] $tfvcPath
    )
    try
    {
        $tfsChangesetApiUrl = $tfsCollectionURL + '/_apis/tfvc/changesets?searchCriteria.itemPath=' + $tfvcPath + '&' + $apiVersion + '&$top=50000'
        #Write-Host $tfsChangesetApiUrl
        $tfsChangesetObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsChangesetApiUrl -ErrorAction Stop
        #Write-Host $tfsChangesetObject
        $changesets = $tfsChangesetObject.value.changesetId
        #Write-Host $changesets
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $changesets
}

# Get Associated Work Items
function GetAssociatedWorkItems
{
    param
    (
        [Parameter(Mandatory=$true)][string] $changeset
    )
    try
    {
        $tfsACWIApiUrl = $tfsCollectionURL + '/_apis/tfvc/changesets/' + $changeset + '/workItems?' + $apiVersion
        #Write-Host $tfsACWIApiUrl
        $tfsACWIObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsACWIApiUrl -ErrorAction Stop
        #Write-Host $tfsACWIObject
        $workitems = $tfsACWIObject.value.id
        #Write-Host $workitems
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $workitems
}

try
{
    $outputFile = "$PSScriptRoot\AssociatedWI.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }

        "{0}`t{1}" -f "Changeset ID", "WorkItem ID" | Out-File -FilePath $outputFile
        

    $tfvcChangesets = GetChangesets $tfsCollectionURL $tfvcPath
    foreach ($changeset in $tfvcChangesets)
    {
        $changesetWorkItems = GetAssociatedWorkItems $changeset
        foreach($workItem in $changesetWorkItems)
        {
            "{0}`t{1}" -f $changeset, $workItem | Out-File -FilePath $outputFile -Append
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}