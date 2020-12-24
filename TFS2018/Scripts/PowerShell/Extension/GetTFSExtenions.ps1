<# Script: GetTFSExtensions.ps1
Author: Rehan Bhombal 
Date: 15/01/2020
Description: Script to list all TFS extensions installed in a collection. 
Usage: .\GetTFSExtensions.ps1 'https://tfs2018/tfs/DefaultCollection' #>

param
(
    [Parameter(Mandatory=$true)]
    [string] $tfsCollectionURL
)

$logFile = "$PSScriptRoot\log.txt"

# Get Collection Name from Collecttion URL
$trimmedTfsCollUrl = $tfsCollectionURL.Trim("/")
$collectionName = $trimmedTfsCollUrl.Split("/")[-1]

# Remove existing log  file
if(Test-Path $logFile)
{
    Remove-Item $logFile
}

# Get Extensions
function GetExtensions
{
    param
    (
        [Parameter(Mandatory=$true)][string] $tfsCollectionURL
    )
    try
    {
        $tfsExtensionsApiUrl = $tfsCollectionURL + '/_apis/extensionmanagement/installedextensions?api-version=4.1-preview.1'
        Write-Host $tfsExtensionsApiUrl
        $tfsExtensionsObject = Invoke-RestMethod -UseDefaultCredentials -Uri $tfsExtensionsApiUrl -ErrorAction Stop
        Write-Host $tfsExtensionsObject
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $tfsExtensionsObject
}

try
{
    $outputFile = "$PSScriptRoot\extensions_$collectionName.csv"
    # Remove existing output file
    if(Test-Path $outputFile)
    {
        Remove-Item $outputFile
    }
    "{0}`t{1}`t{2}`t{3}" -f "Extension Name", "Publisher Name", "version", "Last Published" | Out-File -FilePath $outputFile
    $extensions = GetExtensions $tfsCollectionURL
    Write-Host "EXTENSIONS COUNT" $extensions.Count
    foreach ($extension in $extensions.value)
    {
        "{0}`t{1}`t{2}`t{3}" -f $extension.extensionname, $extension.publishername, $extension.version, $extension.lastpublished | Out-File -FilePath $outputFile -Append
    }
}

catch
{
    $_.Exception.Message
    $_ | Out-File -FilePath $logFile -Append
    exit
}