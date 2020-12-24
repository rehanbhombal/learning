<# Script: GetADGroupMembers
Author: Rehan Bhombal 
Date: 15/07/2019
Description: Script to list all members of the AD groups. 
Usage: .\GetADGroupMembers.ps1 'Motor' #>

param
(
    [Parameter(Mandatory=$true)][string] $tfsProject
)

$searchFilter = "G-Company-TFS-$tfsProject-*"
$Groups = Get-ADGroup -Filter {name -like $searchFilter}

$outputFile = "$PSScriptRoot\AD-Group-Members-$tfsProject.csv"
    
# Remove existing output file
if(Test-Path $outputFile)
{
   Remove-Item $outputFile
}

"{0}`t{1}`t{2}" -f "Project","AD Group Name","Members" | Out-File -FilePath $outputFile

foreach($group in $Groups)
{
    $members = ''
    Get-ADGroupMember $group | ForEach-Object {
        If($members) {
              $members=$members + ";" + $_.SamAccountName
           } Else {
              $members=$_.SamAccountName
           }
  }
  
    "{0}`t{1}`t{2}" -f $tfsProject, $group.Name, $members | Out-File -FilePath $outputFile -Append
}