<# Script: GetBuildReleaseTasks.ps1
Author: Rehan Bhombal 
Date: 28/04/2020
Description: Script to list all Build & Release tasks installed in a collection. 
Usage: .\GetBuildReleaseTasks.ps1 'https://tfs2018/tfs/DefaultCollection' #>

param
(
    [Parameter(Mandatory=$false)][string] $tfsCollectionURL = 'https://tfs2018/tfs/DefaultCollection'
)
 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

# Get Tasks
function GetTasks
{
    param
    (
        [Parameter(Mandatory=$true)][string] $tfsCollectionURL
    )
    try
    {
        $tfsTasksApiUrl = $tfsCollectionURL + '/_apis/distributedtask/tasks'
        Write-Host $tfsTasksApiUrl
        $tfsTasksObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsTasksApiUrl -Method Get -ContentType application/json #| Select count, value
        $jsser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $jsser.MaxJsonLength = $jsser.MaxJsonLength * 10
        $jsser.RecursionLimit = 99    
        $outObject = $jsser.DeserializeObject($tfsTasksObject)
        #Write-Host $tfsTasksObject
        $tfsTasks = $outObject.value
        #Write-Host $tfsTasks
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $tfsTasks
}

try
{
    $outputFile = "$PSScriptRoot\tasks.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }
    "{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f "Id", "Name", "Category", "Version", "Visibility", "Description" | Out-File -FilePath $outputFile
    $tasks = GetTasks $tfsCollectionURL
    Write-Host "TASKS COUNT" $tasks.Count
    foreach ($task in $tasks)
    {
        $visibilitySeperated = $task.visibility | % {$_}
        $visiblity = $visibilitySeperated -join ','
        [String]$taskVersion = [String]$task.version.major + '.' + [String]$task.version.minor + '.' + [String]$task.version.patch
        "{0}`t{1}`t{2}`t{3}`t{4}`t{5}" -f $task.id, $task.name, $task.category, $taskVersion, $visiblity, $task.description | Out-File -FilePath $outputFile -Append
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}

#https://stackoverflow.com/questions/49273863/how-to-get-tfs-build-steps-with-the-rest-api