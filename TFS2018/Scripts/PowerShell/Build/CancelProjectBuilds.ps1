<# Script: DisableAllBuilds
Author: Rehan Bhombal 
Date: 20/03/2020
Description: Script to cancel all builds in not started state. 
Usage: .\DisableAllBuilds.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsCollectionUrl = 'https://tfs2018/tfs/DefaultCollection',
    [Parameter(Mandatory=$true)][string] $tfsProjectName = '<ProjectName>'
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
    $tfsProjectUrl = "$($tfsCollectionUrl)/$($tfsProjectName)"
    $BuildDefsUrl = "$tfsProjectUrl/_apis/build/definitions?$apiVersion" # TFS build definitions URL
    Write-Host $BuildDefsUrl
    $BuildsUrl = "$tfsProjectUrl/_apis/build/builds"  #TFS Builds URL

    $Builds = (Invoke-RestMethod -Uri ($BuildDefsUrl) -Method GET -UseDefaultCredentials).value | Select id,name # get all builds 
    #for filtering use : |  Where-Object {$_.name -like "*Your Pattern*"}

    foreach ($build in $builds)
    {
        $command = "$($BuildsUrl)?api-version=3.2-preview.3&resultFilter=inprogress&definitions=$($build.id)&queryOrder=finishTimeDescending"
        Write-Host $command
        $Ids = (((Invoke-RestMethod -Method Get -Uri $command -UseDefaultCredentials).value) | where status -like "*notStarted*").id # get waiting builds id's

        foreach($id in $Ids)
        {
            $uri =  "$($BuildsUrl)/$($id)?api-version=2.0" # TFS URI
            $body = '{"status":4}' # body 
            $result = Invoke-RestMethod -Method Patch -Uri $uri -UseDefaultCredentials -ContentType 'application/json' -Body $body -Verbose #cancel  build
        }
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}

#https://stackoverflow.com/questions/55583196/how-can-i-cancel-delete-a-waiting-build-in-the-queue-using-powershell