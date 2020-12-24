<#
.SYNOPSIS
This script creates a new VSTS project using the VSTS Rest APIs.
.DESCRIPTION
This is a script that wraps the VSTS Rest APIs for creating a project to enable execution via PowerShell
.EXAMPLE
.\New-TeamProject.ps1 -ExistingAccountName "PeteSoftwareStuff" -ProjectName "MyNewProject" -PatToken "reallylongstringofcharacters"
.LINK
https://github.com/petehauge/personal/Scripts/VSTS/New-TeamProject.ps1
#> 
param
(
    [Parameter(Mandatory=$true)]
    [string] $CollectionURL,

    [Parameter(Mandatory=$true)]
    [string] $NewProjectName,

    [Parameter(Mandatory=$true)]
    [string] $PatToken
)

# Clear the errors up front-  helps when running the script multiple times
$error.Clear()

Write-Output "Starting script to create a new Team Project named '$NewProjectName' on the server https://tfs2018/tfs"

# Base64-encodes the Personal Access Token (PAT) appropriately
$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes((":$PatToken")))
$headers = @{Authorization=("Basic {0}" -f $base64AuthInfo)}

$uri = "https://$CollectionURL/_apis/projects?api-version=4.1"

$body=@"
{
    "name": "$NewProjectName",
    "description": "Team Project created automatically for $NewProjectName on TFS AT",
    "capabilities": {
        "versioncontrol": {
            "sourceControlType": "Tfvc"
        },
        "processTemplate": {
            templateTypeId: "9C71A574-A49F-412A-B081-4DC061BA2DE1"
        }
    }
}
"@

# Make the call to queue up a project creation
$result = Invoke-RestMethod -Uri $uri -Method Post -ContentType "application/json" -Headers $headers -Body $body

# Monitor the async operation until it's complete
$asyncOperation = Invoke-RestMethod -Uri $result.url -Method Get -ContentType "application/json" -Headers $headers
while ($asyncOperation.status -eq "inProgress") {
    Start-Sleep -Seconds 5
    $asyncOperation = Invoke-RestMethod -Uri $result.url -Method Get -ContentType "application/json" -Headers $headers
}

# Check the result
if ($asyncOperation.status -eq "succeeded") {
    Write-Output "Successfully created TFS project named $NewProjectName"
}
else {
    Write-Error "Error creating TFS Project named $NewProjectName"
}

# Output the ayncOperation details in case there are other messages
Write-Output $asyncOperation