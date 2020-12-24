<# Script: FixVSGitCloneIssue
Author: Rehan Bhombal 
Date: 12/11/2019
Description: Script to fix Git Clone Issue with VS 2017 IDE. 
Usage: .\FixVSGitCloneIssue.ps1
This script requires powershell to be run with elevated permissions#>

$vswherePath = "${Env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if([System.IO.File]::Exists($vswherePath))
{

    $commandParemeters = "-property InstallationPath"
    $VSInstallationPath = & $vswherePath @('-property','InstallationPath')
}

$certificate = "-----BEGIN CERTIFICATE-----
*
-----END CERTIFICATE-----"

function AddCorporateCertificate
{
    Param ([String]$path)
    if([System.IO.File]::Exists($path))
    {
        Write-Host "Certificate File 'ca-bundle.crt' Found!"
        # if corporate certificate is missing add it
        if((Select-String -Path $path -Pattern "MIID8DCCAtigAwIBAgIQbo7QYMe977REYAe54Ui").Matches.Count -eq 0)
        {
            Add-Content $path $certificate
			Write-Host "Corporate certificate added!"
        }
        else
        {
            Write-Host "Corporate certificate exists!"
        }
    }
}

foreach($path in $VSInstallationPath)
{
    # Certificate to be added to Git Certificate package in VS 2017 and later installations
    $VSGitCertificatePath = "$path\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\mingw32\ssl\certs\ca-bundle.crt"
    AddCorporateCertificate $VSGitCertificatePath
}