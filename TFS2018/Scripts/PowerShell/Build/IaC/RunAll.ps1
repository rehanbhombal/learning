<# Script: RunAll.ps1
Author: Rehan Bhombal 
Date: 17/04/2020
Description: Script to install and configure TFS agents. 
Usage: .\RunAll.ps1 -TfsUrl 'https://tfs2018/tfs' -ServiceAccountUsername '<Domain>\<BuildAccount>' -ServiceAccountPassword '<BuildAccountPassword>' -PoolName 'Default' -AgentName 'A5' -InstallAgentDir 'C:\A\5' #>

# Define input parameters
param
(
	[string]$TfsUrl = $(throw "TfsUrl must be provided."),
	[string]$ServiceAccountUsername = $(throw "ServiceAccountUsername must be provided."),
	[string]$ServiceAccountPassword = $(throw "ServiceAccountPassword must be provided."),
	[string]$PoolName = $(throw "PoolName must be provided."),
	[string]$AgentName = $(throw "AgentName must be provided."),
	[string]$InstallAgentDir = $(throw "InstallAgentDir must be provided.")
)

$WorkFolder = '_work'
$ToolDirectory = "$InstallAgentDir\$WorkFolder\_tool"
$AgentCertificatePath = "$InstallAgentDir\externals\git\mingw64\ssl\certs\ca-bundle.crt"
$certificate = "-----BEGIN CERTIFICATE-----
*
-----END CERTIFICATE-----"

# Check if Install Agent directory exists else create it.
if(!(Test-Path -Path $InstallAgentDir))
{
    New-Item -ItemType Directory -Path $InstallAgentDir
    Write-Host "Agent Directory Created!"    
}
else
{
	Write-Host "Agent Directory Already Exists, Exiting...!"
	exit
}

# Unzip agent zip file to agent directory.
. $PSScriptRoot\Unzip.ps1 -zippath 'vsts-agent-win-x64-2.136.1.zip' -outputpath $InstallAgentDir

# Copy Company Certificate PEM file to agent directory.
#Copy-Item $PSScriptRoot\Certificate.pem -Destination $InstallAgentDir

# Cconfigure agent as per the parameters provided.
. $PSScriptRoot\InstallAgent.ps1 -TfsUrl $TfsUrl -ServiceAccountUsername $ServiceAccountUsername -ServiceAccountPassword $ServiceAccountPassword -AgentName $AgentName -PoolName $PoolName -InstallAgentDir $InstallAgentDir -WorkFolder $WorkFolder

# Check if '_tool' directory exists under '_work' directory else create it.
if(!(Test-Path -Path $ToolDirectory))
{
    New-Item -ItemType Directory -Path $ToolDirectory
    Write-Host "Tool Directory Created!"    
}

# Create cache for NuGet as some Build Servers may not have access to internet.
. $PSScriptRoot\Unzip.ps1 -zippath 'NuGet.zip' -outputpath $InstallAgentDir\$WorkFolder\_tool\

# Add Certificate for Git Certificate Store
if([System.IO.File]::Exists($AgentCertificatePath))
{
    Write-Host "Certificate File 'ca-bundle.crt' Found!"
    # if corporate certificate is missing add it
    if((Select-String -Path $AgentCertificatePath -Pattern "MIID8DCCAtigAwIBAgIQbo7QYMe977REYAe54Ui").Matches.Count -eq 0)
    {
        Add-Content $AgentCertificatePath $certificate
		Write-Host "Corporate certificate added to Agent Git Certificate Store!"
    }
    else
    {
            Write-Host "Corporate certificate exists!"
    }
}

# Start-Sleep -Seconds 90
# . $PSScriptRoot\RunTestBuild.ps1 -AgentName $AgentName 