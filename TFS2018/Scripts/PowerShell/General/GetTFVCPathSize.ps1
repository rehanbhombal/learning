<# Script: GetTFVCPathSize.ps1
Author: Rehan Bhombal 
Date: 22/08/2019
Description: Script to list all Work items associated with changesets for path. 
Usage: .\GetTFVCPathSize.ps1 'https://tfs2018/tfs/DefaultCollection' '$/<ProjectName>' #>

param 
(
	 [Parameter(Mandatory=$true, Position=0)]
     [string] 
     $tfsCollectionUrl,
     [Parameter(Mandatory=$true, Position=2)]
     [string]
     $tfvcpath
)

#SQL
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo')
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc')
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO')

Write-Host "TFS COLLECTION URL:" $tfsCollectionUrl
Write-Host "TFVC PATH:" $tfvcpath

$apiVersion = "api-version=2.0"

$collection = $tfsCollectionUrl.Split('//')[4]

$tfsDatabase = "Tfs_" + $collection

Write-Host "TFS DB:" $tfsDatabase

$tfsProjectName = $tfvcPath.Split('//')[1]

Write-Host "TFS PROJECT NAME:" $tfsProjectName

function GetProject
{
    param 
    (
	     [Parameter(Mandatory=$true)][string] $collection,
         [Parameter(Mandatory=$true)][string] $project,
         [Parameter(Mandatory=$false)][string] $personalAccessToken
    )
    try
    {
        $tfsCollUrl = "$($tfsCollectionUrl)/_apis/projects/?$($apiVersion)&`$top=500"
        Write-Host "REST API URL:" $tfsCollUrl
        if($personalAccessToken)
        {
             Write-Host "Using PAT for Project"
            $tfsProjects = Invoke-RestMethod -Method Get -ContentType application/json -Uri $tfsCollUrl -Headers @{Authorization=("Basic {0}" -f $base64authinfo)} -ErrorAction Stop
            #Write-Host "TFS PROJECT:" $tfsProjects
        }
        else
        {
            $tfsProjects = Invoke-RestMethod -UseDefaultCredentials -uri $tfsCollUrl -ErrorAction Stop
            #Write-Host "TFS PROJECT:" $tfsProjects
        }
        $projectObject = $tfsProjects.value | where name -eq $project
        #Write-Host "PROJECT OBJECT:" $projectObject
    }
    catch
    {
        $_.Exception.Message
        $_ | Out-File -FilePath $logFile -Append
        exit
    }
    return $projectObject
}

Function GetSizeOfFolder
{
<#
.SYNOPSIS This function returns the size of files that are download on the agent during mapping
#>
 param( 
        [Parameter(Mandatory=$true)][string]$DbServerName,
        [Parameter(Mandatory=$true)][string]$DatabaseName,
		[Parameter(Mandatory=$true)][string]$mapping #mapping should contains project uri instead name and all special character should be replaced e.g. -,"
      )
	begin{}
	process
	{
		$server =  New-Object Microsoft.SqlServer.Management.Smo.Server $DbServerName
		$db = $server.Databases.Item($DatabaseName);

[String] $sql = @"
USE #DatabaseName; 
;WITH getFilesSize
as
  (
SELECT -- item path 
Distinct(Files.FileId),
    Versions.FullPath AS ItemPath,
    -- size of latest version on disk 
	MetaData.FileLength as Size,
	-- check if deleted or not
    CASE WHEN Versions.DeletionId = 0 THEN 0 
        ELSE 1 END AS Deleted 
	FROM tbl_FileReference Files, tbl_Version Versions, tbl_FileMetadata MetaData
	WHERE -- get item latest version 
    Versions.VersionTo = 2147483647 
    -- join to table with sizes
	AND Versions.FileId = Files.FileId
    -- return only large files
	AND Files.ResourceId = MetaData.ResourceId
	--Only not deleted
	AND Versions.DeletionId = 0
	--And those files which are in
	AND Versions.FullPath Like '#ReplacePath%'
  )

SELECT
SUM(Size)/1024/1024 as SizeInMB
FROM getFilesSize
"@

	if(($DatabaseName) -and ($mapping))
	{
		$sql=$sql.Replace("#DatabaseName",$DatabaseName)
		$sql=$sql.Replace("#ReplacePath",$mapping)

		try	
		{	
			$result = $db.ExecuteWithResults($sql)
		}
		catch [Exception] 
		{
			# Discovering the full type name of an exception
			Write-Host $_.Exception.gettype().fullName
			Write-Host $_.Exception.message
			# Discovering the full type name of an exception
			#LogError $Error[0]
			break
		}
	}
		if($result.Tables)
		{
            #Write-Host "SQL Result:" $result
			return $($result.Tables.SizeInMB)
		}
	}
	end{}
}

$tfsProject = GetProject $collection $tfsProjectName

$tfsProjectID = $tfsProject.ID

Write-Host "TFS PROJECT ID:" $tfsProjectID

$tfvcPathForSql = $tfvcPath	-replace "$($tfsProjectName)", "$($tfsProjectID.split("/")[-1])" `
			    -replace "-",'"'`
			    -replace '/','\'`
			    -replace '_','>'

Write-Host "TFVC SQL Path" $tfvcPathForSql

$databaseInstance = "E75LDNWP0831V\TFS_2015_ST"

$sizeOfFolder = GetSizeOfFolder $databaseInstance $tfsDatabase $tfvcPathForSql

Write-Host "Size of Folder:" $sizeOfFolder "MB"