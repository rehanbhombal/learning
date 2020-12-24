<# Script: GetSecurityNamespaceWithActions
Author: Rehan Bhombal 
Date: 21/07/2020
Description: Script to list Security Namespace and their actions. 
Usage: .\GetSecurityNamespaceWithActions.ps1 'https://tfs2018/tfs/DefaultCollection' 
Reference: https://developercommunity.visualstudio.com/content/problem/393728/security-namespace-api-example-not-correct.html #>
param
(
    [Parameter(Mandatory=$true)][string] $tfsCollURL = "https://tfs2018/tfs/DefaultCollection"
)

$apiVersion = "api-version=4.1" 
$logFile = "$PSScriptRoot\log.txt"

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

$outputFile = "$PSScriptRoot\NamespaceWithActions.csv"
# Remove existing output file
if(Test-Path $outputFile)
{
    Remove-Item $outputFile
}
"{0}`t{1}" -f "Name", "Action" | Out-File -FilePath $outputFile

try
{
    $url = "$tfsCollURL/_apis/securitynamespaces/00000000-0000-0000-0000-000000000000?$apiVersion"
    $result = Invoke-RestMethod -Uri $url -UseDefaultCredentials -Method GET
    Write-Host "Namespace Count:" $result.count
    foreach($namespace in $result.value)
    {
        #Write-output $p.name
        foreach($action in $namespace.actions)
        {
            "{0}`t{1}" -f $namespace.name, $action.name | Out-File -FilePath $outputFile -Append
        }
    }
}
catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}
<#
To get the list of all security namespaces:
`GET https://dev.azure.com/{organization}/_apis/securitynamespaces?api-version=5.0-preview.1`
Just specify the {securityNamespace ID} to get the specific securityNamespace:
`GET https://dev.azure.com/{organization}/_apis/securitynamespaces/58450c49-b02d-465a-ab12-59ae512d6531?api-version=5.0-preview.1`
For on-premise TFS 2018, you need to specify the ID `00000000-0000-0000-0000-000000000000` in the URL:
So, to get a list of security namespaces, you can call below REST API:
GET https://server:8080/tfs/DefaultCollection/_apis/securitynamespaces/00000000-0000-0000-0000-000000000000?api-version=4.1
#>
