<# Script: DisableAllBuildDefs
Author: Rehan Bhombal 
Date: 18/03/2020
Description: Script to list all Collections and Team Projects on the TFS Server. 
Usage: .\GetBuildDefinitionDetails.ps1 'https://tfs2018/tfs/DefaultCollection' '<ProjectName>' #>

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
    $buildDefsUrl = "$($tfsCollectionUrl)/$($tfsProjectName)/_apis/build/definitions?$($apiversion)"
    $buildDefs = Invoke-RestMethod -UseDefaultCredentials -Uri $buildDefsUrl -ErrorAction Stop
    [int]$buildDefsCount = $buildDefs.Count
    if($buildDefsCount -gt 0)
    {
        foreach ($buildDef in $buildDefs.value)
        {
            $buildDefName = $buildDef.name
            Write-Host "Build Name:" $buildDefName -ForegroundColor Yellow
            $buildDefId = $buildDef.id
            $buildDefIdUrl = "$($tfsCollectionUrl)/$($tfsProjectName)/_apis/build/definitions/$($buildDefId)?$($apiversion)"
            $buildDefIdFormat = Invoke-RestMethod -UseDefaultCredentials -Uri $buildDefIdUrl -Method Get -ContentType application/json
            if($buildDefIdFormat.queueStatus -eq 'enabled')
            {
                Write-Host "Disabling Build Definition $buildDefName ..."
                $buildDefIdFormat.queueStatus = "disabled"
                $buildDefJson = $buildDefIdFormat | ConvertTo-Json -Depth 100 -Compress
                $def = [System.Text.Encoding]::UTF8.GetBytes($buildDefJson)
                $header = @{ "Accept" = $apiVersion }
                $response = Invoke-RestMethod -Uri $buildDefIdUrl -Method Put -Body $def -ContentType application/json -UseDefaultCredentials -Headers $header
            }
            else
            {
                Write-Host "Build Definition $buildDefName is already disabled."
            }
        }
    }
    else
    {
        Write-Host "The project $tfsProjectName has $buildDefsCount build definitions."
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    Write-Host "Response:" $response
    exit
}