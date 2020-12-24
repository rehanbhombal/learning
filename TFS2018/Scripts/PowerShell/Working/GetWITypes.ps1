<# Script: GetWITypes
Author: Rehan Bhombal 
Date: 09/07/2020
Description: Script to list types of work items in a Team Project. 
Usage: .\GetWITypes.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' 
Reference: https://developercommunity.visualstudio.com/content/problem/781441/work-item-type-rest-api-does-not-expose-properties.html #>
param
(
    [Parameter(Mandatory=$true)][string] $tfsCollURL = "https://tfs2018/tfs/DefaultCollection",
    [Parameter(Mandatory=$true)][string] $tfsProject = "<ProjectName>"
)

$apiVersion = "api-version=4.1" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

$outputFile = "$PSScriptRoot\workitemtype_$tfsProject.csv"
# Remove existing output file
if(Test-Path $outputFile)
{
    Remove-Item $outputFile
}
"{0}`t{1}" -f $tfsProject, "Count" | Out-File -FilePath $outputFile

try
{
    #https://{instance}/{collection}/{project}/_apis/wit/workitemtypes?api-version=4.1
    $url = "$tfsCollURL/$tfsProject/_apis/wit/workitemtypes?$apiVersion"
    $result = Invoke-RestMethod -Uri $url -UseDefaultCredentials -Method GET
    $jsser = New-Object System.Web.Script.Serialization.JavaScriptSerializer
    $jsser.MaxJsonLength = $jsser.MaxJsonLength * 10
    $jsser.RecursionLimit = 99    
    $outObject = $jsser.DeserializeObject($result)
    Write-Host "Work Item Type Count:" $outObject.count
    foreach($p in $outObject.value)
    {
        #Write-output $p.name
        "{0}`t{1}" -f $p.name, $p.Count | Out-File -FilePath $outputFile -Append
    }
}
catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}